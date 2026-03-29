// lib/features/admin/presentation/screens/tabs/admin_employee_tab.dart

import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';

class AdminEmployeeTab extends StatefulWidget {
  const AdminEmployeeTab({super.key});

  @override
  State<AdminEmployeeTab> createState() => _AdminEmployeeTabState();
}

class _AdminEmployeeTabState extends State<AdminEmployeeTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _employees = [];
  List<dynamic> _positions = [];
  bool _loading = false;
  String _statusFilter = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _statusFilter = _tabController.index == 0 ? 'ACTIVE' : 'RESIGNED';
      _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final empRes = await ApiClient.get('/api/admin/employees?status=$_statusFilter');
      final posRes = await ApiClient.get('/api/admin/positions');
      if (mounted) {
        setState(() {
          _employees = empRes.data ?? [];
          _positions = posRes.data ?? [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fireEmployee(Map<String, dynamic> emp) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pecat Karyawan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pecat ${emp['name']}? Status karyawan akan menjadi RESIGNED dan tidak bisa login lagi.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Alasan (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pecat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await ApiClient.post('/api/admin/employees/fire',
          {'user_id': emp['id'], 'reason': reasonCtrl.text});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? '${emp['name']} berhasil diberhentikan' : (res.message ?? 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ));
      if (res.success) _loadData();
    } catch (_) {}
  }

  Future<void> _reactivateEmployee(Map<String, dynamic> emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aktifkan Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Aktifkan kembali ${emp['name']}? Karyawan akan bisa login kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await ApiClient.post('/api/admin/employees/reactivate', {'user_id': emp['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Karyawan berhasil diaktifkan' : (res.message ?? 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ));
      if (res.success) _loadData();
    } catch (_) {}
  }

  Future<void> _resetDevice(Map<String, dynamic> emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Device ID', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Reset device ID ${emp['name']}? Karyawan bisa login di HP baru setelah ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await ApiClient.post('/api/admin/reset-device', {'user_id': emp['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Device ID berhasil direset' : (res.message ?? 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ));
    } catch (_) {}
  }

  void _showAssignPosition(Map<String, dynamic> emp) {
    String? selectedPositionId = emp['position_id'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Jabatan - ${emp['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPositionId,
                decoration: InputDecoration(
                  labelText: 'Pilih Jabatan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('— Tidak ada jabatan —')),
                  ..._positions.map((p) => DropdownMenuItem(
                        value: p['id'] as String,
                        child: Text('${p['name']} (${_formatSalary(p['salary'])})'),
                      )),
                ],
                onChanged: (v) => setModalState(() => selectedPositionId = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D64F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final res = await ApiClient.post('/api/admin/positions/assign',
                          {'user_id': emp['id'], 'position_id': selectedPositionId ?? ''});
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res.success ? 'Jabatan berhasil diset' : (res.message ?? 'Gagal')),
                        backgroundColor: res.success ? Colors.green : Colors.red,
                      ));
                      if (res.success) _loadData();
                    } catch (_) {}
                  },
                  child: const Text('Simpan Jabatan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> emp) {
    final isActive = emp['status'] == 'ACTIVE';
    final hasDevice = (emp['device_id'] ?? '').toString().isNotEmpty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF4D64F5).withAlpha(30),
              child: Text(
                (emp['name'] ?? 'K').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4D64F5)),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(emp['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Center(child: Text(emp['email'] ?? '', style: TextStyle(color: Colors.grey.shade600))),
            const SizedBox(height: 4),
            Center(
              child: Chip(
                label: Text(emp['status'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: isActive ? Colors.green : Colors.red,
              ),
            ),
            const Divider(height: 24),
            _detailRow('Jabatan', emp['position_name'] ?? '-'),
            _detailRow('Gaji Pokok', _formatSalary(emp['salary'])),
            _detailRow('Telepon', emp['phone'] ?? '-'),
            _detailRow('Alamat', emp['address'] ?? '-'),
            _detailRow('Tgl Lahir', emp['birth_date'] ?? '-'),
            const Divider(height: 24),
            if (isActive) ...[
              _actionButton(Icons.work_rounded, 'Set Jabatan', Colors.blue, () { Navigator.pop(ctx); _showAssignPosition(emp); }),
              const SizedBox(height: 8),
              if (hasDevice)
                _actionButton(Icons.phone_android_rounded, 'Reset Device ID', Colors.orange, () { Navigator.pop(ctx); _resetDevice(emp); }),
              const SizedBox(height: 8),
              _actionButton(Icons.person_remove_rounded, 'Pecat Karyawan', Colors.red, () { Navigator.pop(ctx); _fireEmployee(emp); }),
            ] else ...[
              _actionButton(Icons.person_add_rounded, 'Aktifkan Kembali', Colors.green, () { Navigator.pop(ctx); _reactivateEmployee(emp); }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withAlpha(100)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  String _formatSalary(dynamic salary) {
    if (salary == null) return '-';
    final val = (salary as num).toDouble();
    if (val == 0) return '-';
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF4D64F5),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: const [Tab(text: 'Aktif'), Tab(text: 'Diberhentikan')],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _employees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Tidak ada karyawan', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _employees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final e = _employees[i] as Map<String, dynamic>;
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF4D64F5).withAlpha(30),
                                child: Text(
                                  (e['name'] ?? 'K').substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4D64F5)),
                                ),
                              ),
                              title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  if (e['position_name'] != null && (e['position_name'] as String).isNotEmpty)
                                    Text(e['position_name'],
                                        style: const TextStyle(color: Color(0xFF4D64F5), fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showDetail(e),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
