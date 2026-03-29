// lib/features/employee/presentation/screens/tabs/employee_attendance_tab.dart

import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';

class EmployeeAttendanceTab extends StatefulWidget {
  const EmployeeAttendanceTab({super.key});

  @override
  State<EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  Map<String, dynamic>? _todayData;
  bool _loading = false;
  bool _actionLoading = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/employee/attendance/today');
      final name = await SessionStorage.getUserName();
      if (mounted) {
        setState(() {
          _todayData = res.data as Map<String, dynamic>?;
          _userName = name;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doAction(String action) async {
    setState(() => _actionLoading = true);
    try {
      final res = await ApiClient.post('/api/employee/attendance/$action', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success
            ? (action == 'checkin' ? '✅ Check-in berhasil!' : '✅ Check-out berhasil!')
            : (res.message ?? 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ));
      if (res.success) _load();
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final att = _todayData?['attendance'] as Map<String, dynamic>?;
    final settings = _todayData?['settings'] as Map<String, dynamic>?;
    final hasCheckedIn = att != null && att['check_in_time'] != null && att['check_in_time'].toString().isNotEmpty;
    final hasCheckedOut = att != null && att['check_out_time'] != null && att['check_out_time'].toString().isNotEmpty;
    final now = _todayData?['current_time'] ?? '--:--:--';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Greeting
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${_userName ?? 'Karyawan'}! 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_todayData?['date'] ?? '', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Jam sekarang: $now', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Status absensi hari ini
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Kehadiran Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusChip(Icons.login_rounded, 'Check-In',
                          att?['check_in_time']?.toString().substring(11, 19) ?? '--:--',
                          hasCheckedIn ? Colors.green : Colors.grey),
                      const SizedBox(width: 12),
                      _statusChip(Icons.logout_rounded, 'Check-Out',
                          att?['check_out_time']?.toString().substring(11, 19) ?? '--:--',
                          hasCheckedOut ? Colors.blue : Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol utama
          if (!hasCheckedIn) ...[
            _buildActionButton(
              icon: Icons.login_rounded,
              label: 'Absen Masuk',
              color: const Color(0xFF2E7D32),
              loading: _actionLoading,
              onTap: () => _doAction('checkin'),
            ),
            if (settings != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Jam check-in: ${settings['check_in_start'] ?? '-'} – ${settings['check_in_end'] ?? '-'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ),
          ] else if (!hasCheckedOut) ...[
            _buildActionButton(
              icon: Icons.logout_rounded,
              label: 'Absen Pulang',
              color: Colors.blue.shade700,
              loading: _actionLoading,
              onTap: () => _doAction('checkout'),
            ),
            if (settings != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Jam check-out: ${settings['check_out_start'] ?? '-'} – ${settings['check_out_end'] ?? '-'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Absensi hari ini selesai! ✨',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, String time, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            Text(time, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
