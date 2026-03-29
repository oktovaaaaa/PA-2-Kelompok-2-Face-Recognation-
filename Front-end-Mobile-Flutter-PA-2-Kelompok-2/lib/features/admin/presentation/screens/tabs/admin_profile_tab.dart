// lib/features/admin/presentation/screens/tabs/admin_profile_tab.dart

import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _company;
  Map<String, dynamic>? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profileRes = await ApiClient.get('/api/profile');
      final companyRes = await ApiClient.get('/api/admin/company');
      final settingsRes = await ApiClient.get('/api/admin/attendance-settings');
      if (mounted) {
        setState(() {
          _profile = profileRes.data as Map<String, dynamic>?;
          _company = companyRes.data as Map<String, dynamic>?;
          _settings = settingsRes.data as Map<String, dynamic>?;
        });
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
              const SizedBox(height: 16),
              _buildField(nameCtrl, 'Nama Lengkap', Icons.person_rounded),
              _buildField(phoneCtrl, 'Nomor Telepon', Icons.phone_rounded, keyboardType: TextInputType.phone),
              _buildField(birthPlaceCtrl, 'Tempat Lahir', Icons.location_city_rounded),
              _buildField(birthDateCtrl, 'Tanggal Lahir (YYYY-MM-DD)', Icons.calendar_today_rounded),
              _buildField(addressCtrl, 'Alamat', Icons.home_rounded, maxLines: 2),
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
                    final res = await ApiClient.put('/api/profile', {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'birth_place': birthPlaceCtrl.text.trim(),
                      'birth_date': birthDateCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? 'Profil diperbarui' : (res.message ?? 'Gagal')),
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

  void _editCompany() {
    final nameCtrl = TextEditingController(text: _company?['Name'] ?? _company?['name'] ?? '');
    final addressCtrl = TextEditingController(text: _company?['Address'] ?? _company?['address'] ?? '');
    final emailCtrl = TextEditingController(text: _company?['Email'] ?? _company?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: _company?['Phone'] ?? _company?['phone'] ?? '');

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
              const Text('Edit Data Perusahaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _buildField(nameCtrl, 'Nama Perusahaan', Icons.business_rounded),
              _buildField(addressCtrl, 'Alamat Perusahaan', Icons.location_on_rounded, maxLines: 2),
              _buildField(emailCtrl, 'Email Perusahaan', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
              _buildField(phoneCtrl, 'Telepon Perusahaan', Icons.phone_rounded, keyboardType: TextInputType.phone),
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
                    final res = await ApiClient.post('/api/admin/company', {
                      'Name': nameCtrl.text.trim(),
                      'Address': addressCtrl.text.trim(),
                      'Email': emailCtrl.text.trim(),
                      'Phone': phoneCtrl.text.trim(),
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? 'Data perusahaan diperbarui' : (res.message ?? 'Gagal')),
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

  void _editAttendanceSettings() {
    final checkInStartCtrl = TextEditingController(text: _settings?['check_in_start'] ?? '07:00');
    final checkInEndCtrl = TextEditingController(text: _settings?['check_in_end'] ?? '09:00');
    final checkOutStartCtrl = TextEditingController(text: _settings?['check_out_start'] ?? '16:00');
    final checkOutEndCtrl = TextEditingController(text: _settings?['check_out_end'] ?? '18:00');
    final penaltyCtrl = TextEditingController(
        text: (_settings?['alpha_penalty'] ?? 0).toString());

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
              const Text('Pengaturan Absensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Format waktu: HH:MM (contoh: 07:00)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Jam Check-In', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildField(checkInStartCtrl, 'Mulai', Icons.login_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(checkInEndCtrl, 'Selesai', Icons.login_rounded)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Jam Check-Out', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildField(checkOutStartCtrl, 'Mulai', Icons.logout_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(checkOutEndCtrl, 'Selesai', Icons.logout_rounded)),
                ],
              ),
              const SizedBox(height: 8),
              _buildField(penaltyCtrl, 'Denda Alpha per Hari (Rp)', Icons.money_off_rounded,
                  keyboardType: TextInputType.number),
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
                    final res = await ApiClient.put('/api/admin/attendance-settings', {
                      'check_in_start': checkInStartCtrl.text.trim(),
                      'check_in_end': checkInEndCtrl.text.trim(),
                      'check_out_start': checkOutStartCtrl.text.trim(),
                      'check_out_end': checkOutEndCtrl.text.trim(),
                      'alpha_penalty': double.tryParse(penaltyCtrl.text.trim()) ?? 0,
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.success ? 'Pengaturan disimpan' : (res.message ?? 'Gagal')),
                      backgroundColor: res.success ? Colors.green : Colors.red,
                    ));
                    if (res.success) _load();
                  },
                  child: const Text('Simpan Pengaturan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
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

  String _val(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return '-';
    for (final k in keys) {
      final v = map[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profil diri
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_rounded, color: Color(0xFF4D64F5)),
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
                _infoRow('Nama', _val(_profile, ['name'])),
                _infoRow('Email', _val(_profile, ['email'])),
                _infoRow('Telepon', _val(_profile, ['phone'])),
                _infoRow('Tempat Lahir', _val(_profile, ['birth_place'])),
                _infoRow('Tgl Lahir', _val(_profile, ['birth_date'])),
                _infoRow('Alamat', _val(_profile, ['address'])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Data perusahaan
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business_rounded, color: Color(0xFF4D64F5)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Data Perusahaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    TextButton.icon(
                      onPressed: _editCompany,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const Divider(),
                _infoRow('Nama', _val(_company, ['Name', 'name'])),
                _infoRow('Alamat', _val(_company, ['Address', 'address'])),
                _infoRow('Email', _val(_company, ['Email', 'email'])),
                _infoRow('Telepon', _val(_company, ['Phone', 'phone'])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Pengaturan absensi
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Color(0xFF4D64F5)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Pengaturan Absensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    TextButton.icon(
                      onPressed: _editAttendanceSettings,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const Divider(),
                _infoRow('Check-In', '${_val(_settings, ['check_in_start'])} – ${_val(_settings, ['check_in_end'])}'),
                _infoRow('Check-Out', '${_val(_settings, ['check_out_start'])} – ${_val(_settings, ['check_out_end'])}'),
                _infoRow('Denda Alpha', 'Rp ${_settings?['alpha_penalty'] ?? 0}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Tombol logout data (sudah ada di AppBar, ini sebagai pengingat)
        OutlinedButton.icon(
          onPressed: () async { await SessionStorage.clear(); },
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Hapus Sesi (Debug)', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
