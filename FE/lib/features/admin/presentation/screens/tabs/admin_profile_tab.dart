// lib/features/admin/presentation/screens/tabs/admin_profile_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/currency_formatter.dart';
import 'package:front_end/features/auth/presentation/screens/landing_screen.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../../common/widgets/app_dialog.dart';
import '../../../../../core/constants/app_constants.dart';

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
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _logout() async {
    final act = await AppDialog.showConfirm(
      context,
      title: 'Keluar Aplikasi',
      message: 'Apakah Anda yakin ingin keluar dari sesi ini?',
      confirmText: 'Ya, Keluar',
      confirmColor: Colors.red.shade600,
    );

    if (act != true) return;
    await SessionStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingScreen()), (_) => false);
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() => _loading = true);
      try {
        final uploadRes = await ApiClient.uploadFile(file);
        if (uploadRes.status) {
          final photoUrl = uploadRes.data['url'];
          // Update profile dengan photo_url baru
          await ApiClient.put('/api/profile', {
            'name': _profile?['name'] ?? '',
            'phone': _profile?['phone'] ?? '',
            'birth_place': _profile?['birth_place'] ?? '',
            'birth_date': _profile?['birth_date'] ?? '',
            'address': _profile?['address'] ?? '',
            'photo_url': photoUrl,
          });
          setState(() {
            _imageFile = file;
            if (_profile != null) {
              _profile!['photo_url'] = photoUrl;
            }
          });
          if (mounted) {
            AppDialog.showSuccess(context, 'Foto profil berhasil diperbarui.');
          }
        }
      } catch (e) {
        if (mounted) AppDialog.showError(context, 'Gagal memperbarui foto: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Data Diri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              // Tambahkan Picker di dalam modal
              Center(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx); // Tutup modal dulu
                    _pickImage(); // Jalankan picker
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.1), width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: (_profile?['photo_url'] != null && _profile!['photo_url'].toString().isNotEmpty)
                              ? NetworkImage('${AppConstants.baseUrl}${_profile!['photo_url']}')
                              : null,
                          child: (_profile?['photo_url'] == null || _profile!['photo_url'].toString().isEmpty)
                              ? const Icon(Icons.person_rounded, size: 40, color: Color(0xFF94A3B8))
                              : null,
                        ),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(controller: nameCtrl, label: 'Nama Lengkap', prefixIcon: Icons.person_outline_rounded),
              const SizedBox(height: 16),
              AppTextField(controller: phoneCtrl, label: 'Nomor Telepon', prefixIcon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              AppTextField(controller: birthPlaceCtrl, label: 'Tempat Lahir', prefixIcon: Icons.location_city_outlined),
              const SizedBox(height: 16),
              AppTextField(
                controller: birthDateCtrl, 
                label: 'Tanggal Lahir', 
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: () async {
                  final initial = DateTime.tryParse(birthDateCtrl.text) ?? DateTime(2000, 1, 1);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB))), child: child!);
                    },
                  );
                  if (picked != null) {
                    birthDateCtrl.text = picked.toString().substring(0, 10);
                  }
                },
              ),
              const SizedBox(height: 16),
              AppTextField(controller: addressCtrl, label: 'Alamat', prefixIcon: Icons.home_outlined, maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
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
                    if (res.success) {
                      AppDialog.showSuccess(context, 'Profil Berhasil Diperbarui');
                    } else {
                      AppDialog.showError(context, res.message ?? 'Gagal memperbarui profil');
                    }
                    if (res.success) _load();
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Perusahaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
              const SizedBox(height: 24),
              _buildField(nameCtrl, 'Nama Perusahaan', Icons.business_outlined),
              _buildField(addressCtrl, 'Alamat Lengkap', Icons.map_outlined, maxLines: 2),
              _buildField(emailCtrl, 'Email Resmi', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
              _buildField(phoneCtrl, 'Telepon Kantor', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    if (res.success) {
                      AppDialog.showSuccess(context, 'Instansi Berhasil Diperbarui');
                    } else {
                      AppDialog.showError(context, res.message ?? 'Gagal memperbarui instansi');
                    }
                    if (res.success) _load();
                  },
                  child: const Text('Update Instansi', style: TextStyle(fontWeight: FontWeight.bold)),
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
        text: _settings?['alpha_penalty'] != null
            ? CurrencyInputFormatter.formatNumber((_settings!['alpha_penalty'] as num).toInt())
            : '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jam Operasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
              const SizedBox(height: 24),
              const Text('Absensi Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildField(checkInStartCtrl, 'Mulai', Icons.access_time_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(checkInEndCtrl, 'Selesai', Icons.timer_off_outlined)),
                ],
              ),
              const Text('Absensi Pulang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildField(checkOutStartCtrl, 'Mulai', Icons.access_time_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(checkOutEndCtrl, 'Selesai', Icons.timer_off_outlined)),
                ],
              ),
              _buildField(penaltyCtrl, 'Denda Alpha (Rp)', Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await ApiClient.put('/api/admin/attendance-settings', {
                      'check_in_start': checkInStartCtrl.text.trim(),
                      'check_in_end': checkInEndCtrl.text.trim(),
                      'check_out_start': checkOutStartCtrl.text.trim(),
                      'check_out_end': checkOutEndCtrl.text.trim(),
                      'alpha_penalty': CurrencyInputFormatter.unformat(penaltyCtrl.text.trim()).toDouble(),
                    });
                    if (!mounted) return;
                    if (res.success) {
                      AppDialog.showSuccess(context, 'Pengaturan Tersimpan');
                    } else {
                      AppDialog.showError(context, res.message ?? 'Gagal menyimpan pengaturan');
                    }
                    if (res.success) _load();
                  },
                  child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, List<TextInputFormatter>? inputFormatters, bool readOnly = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
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

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final pts = name.trim().split(RegExp(r'\s+'));
    if (pts.length >= 2) {
      return (pts[0][0] + pts[1][0]).toUpperCase();
    }
    return pts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header Premium
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            image: (_profile?['photo_url'] != null && _profile!['photo_url'].toString().isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage('${AppConstants.baseUrl}${_profile!['photo_url']}'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (_profile?['photo_url'] == null || _profile!['photo_url'].toString().isEmpty)
                              ? Center(
                                  child: Text(
                                    _getInitials(_profile?['name'] ?? 'Admin'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_profile?['name'] ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(_profile?['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
  
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildDataCard(
                    title: 'Data Diri',
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF2563EB),
                    onEdit: _editProfile,
                    rows: [
                      _infoRow('Nama', _val(_profile, ['name'])),
                      _infoRow('Email', _val(_profile, ['email'])),
                      _infoRow('Telepon', _val(_profile, ['phone'])),
                      _infoRow('Tempat Lahir', _val(_profile, ['birth_place'])),
                      _infoRow('Tgl Lahir', _val(_profile, ['birth_date'])),
                      _infoRow('Alamat', _val(_profile, ['address'])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDataCard(
                    title: 'Data Perusahaan',
                    icon: Icons.business_center_outlined,
                    color: const Color(0xFF1E3A8A),
                    onEdit: _editCompany,
                    rows: [
                      _infoRow('Nama', _val(_company, ['Name', 'name'])),
                      _infoRow('Instansi', _val(_company, ['Address', 'address'])),
                      _infoRow('Kontak', _val(_company, ['Phone', 'phone'])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDataCard(
                    title: 'Operasional',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF0F172A),
                    onEdit: _editAttendanceSettings,
                    rows: [
                      _infoRow('Check-In', '${_val(_settings, ['check_in_start'])} - ${_val(_settings, ['check_in_end'])}'),
                      _infoRow('Check-Out', '${_val(_settings, ['check_out_start'])} - ${_val(_settings, ['check_out_end'])}'),
                      _infoRow('Sanksi Alpha', 'Rp ${CurrencyInputFormatter.formatNumber((_settings?['alpha_penalty'] as num?)?.toInt() ?? 0)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard({required String title, required IconData icon, required Color color, required VoidCallback onEdit, required List<Widget> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)))),
                IconButton(onPressed: onEdit, icon: Icon(Icons.edit_note_rounded, color: color, size: 28)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(20), child: Column(children: rows)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)))),
        ],
      ),
    );
  }
}
