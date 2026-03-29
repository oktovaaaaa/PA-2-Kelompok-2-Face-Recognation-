// lib/features/employee/presentation/screens/tabs/employee_profile_tab.dart

import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';

class EmployeeProfileTab extends StatefulWidget {
  const EmployeeProfileTab({super.key});

  @override
  State<EmployeeProfileTab> createState() => _EmployeeProfileTabState();
}

class _EmployeeProfileTabState extends State<EmployeeProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/profile');
      if (res.success && mounted) {
        setState(() => _profile = res.data as Map<String, dynamic>?);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _profile?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone'] ?? '');
    final birthPlaceCtrl = TextEditingController(text: _profile?['birth_place'] ?? '');
    final birthDateCtrl = TextEditingController(text: _profile?['birth_date'] ?? '');
    final addressCtrl = TextEditingController(text: _profile?['address'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Data Diri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Data diri tidak bisa dihapus, hanya bisa diedit.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
              const SizedBox(height: 16),
              _field(nameCtrl, 'Nama Lengkap', Icons.person_rounded),
              _field(phoneCtrl, 'Nomor Telepon', Icons.phone_rounded, keyboardType: TextInputType.phone),
              _field(birthPlaceCtrl, 'Tempat Lahir', Icons.location_city_rounded),
              _field(birthDateCtrl, 'Tanggal Lahir (YYYY-MM-DD)', Icons.calendar_today_rounded),
              _field(addressCtrl, 'Alamat', Icons.home_rounded, maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await ApiClient.put('/api/profile', {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'birth_place': birthPlaceCtrl.text.trim(),
                      'birth_date': birthDateCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? 'Profil berhasil diperbarui' : (res.message ?? 'Gagal')),
                      backgroundColor: res.success ? Colors.green : Colors.red,
                    ));
                    if (res.success) _load();
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  String _v(String key) => _profile?[key]?.toString() ?? '-';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar + nama
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFF2E7D32).withAlpha(30),
                child: Text(
                  (_v('name')).substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 12),
              Text(_v('name'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(_v('email'), style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(_v('position_name') != '-' ? '💼 ${_v('position_name')}' : 'Belum ada jabatan',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_rounded, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Data Diri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    TextButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const Divider(),
                _row('Telepon', _v('phone')),
                _row('Tempat Lahir', _v('birth_place')),
                _row('Tgl Lahir', _v('birth_date')),
                _row('Alamat', _v('address')),
                _row('Status', _v('status')),
              ],
            ),
          ),
        ),
        if (_v('salary') != '0' && _v('salary') != '-') ...[
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.attach_money_rounded, color: Color(0xFF2E7D32)),
              title: const Text('Gaji Pokok', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Rp ${(_profile?['salary'] as num? ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
