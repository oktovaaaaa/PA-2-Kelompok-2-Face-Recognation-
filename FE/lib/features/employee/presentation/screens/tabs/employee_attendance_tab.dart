import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import '../../../../../core/utils/currency_formatter.dart';
import 'package:flutter/services.dart';

class EmployeeAttendanceTab extends StatefulWidget {
  const EmployeeAttendanceTab({super.key});

  @override
  State<EmployeeAttendanceTab> createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  Map<String, dynamic>? _todayData;
  Map<String, dynamic>? _profileData;
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
      final resAtt = await ApiClient.get('/api/employee/attendance/today');
      final resProf = await ApiClient.get('/api/profile');
      final name = await SessionStorage.getUserName();
      
      if (mounted) {
        setState(() {
          _todayData = resAtt.data as Map<String, dynamic>?;
          if (resProf.success) {
             _profileData = resProf.data as Map<String, dynamic>?;
          }
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
        behavior: SnackBarBehavior.floating,
      ));
      if (res.success) _load();
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _formatRp(dynamic amount) {
    if (amount == null) return 'Rp 0';
    return 'Rp ${CurrencyInputFormatter.formatNumber((amount as num).toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _todayData == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    final att = _todayData?['attendance'] as Map<String, dynamic>?;
    final settings = _todayData?['settings'] as Map<String, dynamic>?;
    final hasCheckedIn = att != null && att['check_in_time'] != null && att['check_in_time'].toString().isNotEmpty;
    final hasCheckedOut = att != null && att['check_out_time'] != null && att['check_out_time'].toString().isNotEmpty;
    final now = _todayData?['current_time'] ?? '--:--:--';
    
    final salary = _profileData?['salary'] ?? 0;
    final position = (_profileData?['position_name'] ?? 'Karyawan').toString();
    final isDoneForDay = hasCheckedIn && hasCheckedOut;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${_userName ?? 'Karyawan'} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todayData?['date'] ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        (_userName ?? 'K').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
  
            // Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF2563EB),
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    // Wallet Card Premium
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Estimasi Gaji Pokok',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.work_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      position,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRp(salary),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status Hari Ini',
                                    style: TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isDoneForDay ? 'SELESAI ✔️' : 'PROSES...',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  ),
                                ],
                              ),
                              const Icon(Icons.fingerprint_rounded, color: Colors.white24, size: 40),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
  
                    // Action Buttons Grid-Style
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickAction(
                          icon: Icons.login_rounded,
                          label: 'Check In',
                          color: const Color(0xFF2E7D32),
                          disabled: hasCheckedIn,
                          onTap: () => _doAction('checkin'),
                        ),
                        _buildQuickAction(
                          icon: Icons.logout_rounded,
                          label: 'Check Out',
                          color: const Color(0xFF1E3A8A),
                          disabled: !hasCheckedIn || hasCheckedOut,
                          onTap: () => _doAction('checkout'),
                        ),
                        _buildQuickAction(
                          icon: Icons.assignment_late_rounded,
                          label: 'Izin',
                          color: const Color(0xFFD97706),
                          disabled: false,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gunakan tab Izin di bawah.')));
                          },
                        ),
                        _buildQuickAction(
                          icon: Icons.history_rounded,
                          label: 'Riwayat',
                          color: const Color(0xFF64748B),
                          disabled: false,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gunakan tab Riwayat di bawah.')));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
  
                    // Status Kehadiran Detail 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Log Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(now, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
  
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildStatusRow(
                            icon: Icons.login_rounded,
                            title: 'Masuk Kantor',
                            time: att?['check_in_time']?.toString().substring(11, 16) ?? '--:--',
                            status: hasCheckedIn ? 'Success' : 'Ready',
                            color: hasCheckedIn ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                            isFirst: true,
                          ),
                          Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                          _buildStatusRow(
                            icon: Icons.logout_rounded,
                            title: 'Pulang Kantor',
                            time: att?['check_out_time']?.toString().substring(11, 16) ?? '--:--',
                            status: hasCheckedOut ? 'Success' : (hasCheckedIn ? 'Ready' : 'Wait'),
                            color: hasCheckedOut ? const Color(0xFF1E3A8A) : Colors.grey.shade400,
                            isFirst: false,
                          ),
                        ],
                      ),
                    ),
  
                    if (settings != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Jam: ${settings['check_in_start']} - ${settings['check_in_end']} (In)\n'
                                'Jam: ${settings['check_out_start']} - ${settings['check_out_end']} (Out)',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled || _actionLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: disabled ? Colors.grey.shade200 : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: _actionLoading && label.contains('Masuk') && !disabled // Simple spinner logic
                ? SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: color, strokeWidth: 2))
                : Icon(icon, color: disabled ? Colors.grey.shade400 : color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: disabled ? Colors.grey.shade400 : const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String time,
    required String status,
    required Color color,
    required bool isFirst,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status == 'Selesai' ? color.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Selesai' ? color : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
