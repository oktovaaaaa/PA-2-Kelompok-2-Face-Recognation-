import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../../auth/presentation/screens/pending_employees_screen.dart';
import 'company_settings_screen.dart';
import 'employee_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repo = AuthRepository();
  bool _loadingInvite = false;
  String _generatedToken = '';
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _generateInvite() async {
    setState(() => _loadingInvite = true);
    try {
      final companyId = await SessionStorage.getCompanyId() ?? '';
      final data = await _repo.generateInvite(companyId);
      _generatedToken = (data['token'] ?? '').toString();
      setState(() {});
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loadingInvite = false);
    }
  }

  Future<void> _copyToken() async {
    await Clipboard.setData(ClipboardData(text: _generatedToken));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token disalin ke clipboard!')),
    );
  }

  Future<void> _saveQrCode() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final result = await ImageGallerySaverPlus.saveImage(
        byteData.buffer.asUint8List(),
        quality: 100,
        name: "invite_qr_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['isSuccess'] == true ? 'QR disimpan ke galeri!' : 'Gagal menyimpan QR.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menyimpan gambar.')),
      );
    }
  }

  Future<void> _logout() async {
    final act = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (act != true) return;

    await SessionStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate Invite Karyawan'),
              subtitle: const Text('Buat token undangan baru'),
              trailing: _loadingInvite
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _loadingInvite ? null : _generateInvite,
            ),
          ),
          if (_generatedToken.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Scan Barcode Invitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        child: QrImageView(
                          data: _generatedToken,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _copyToken,
                          icon: const Icon(Icons.copy),
                          label: const Text('Salin Token'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saveQrCode,
                          icon: const Icon(Icons.download),
                          label: const Text('Simpan QR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Pending Employees'),
              subtitle: const Text('Lihat, approve, atau reject karyawan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingEmployeesScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Daftar Karyawan'),
              subtitle: const Text('Lihat karyawan aktif'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeeListScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan Perusahaan'),
              subtitle: const Text('Ubah profil perusahaan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompanySettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}