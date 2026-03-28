// lib/features/auth/presentation/screens/register_choice_screen.dart
import 'package:flutter/material.dart';
import 'register_admin_screen.dart';
import 'barcode_scanner_screen.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Jenis Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Register sebagai Admin'),
              subtitle: const Text('Untuk pemilik perusahaan atau HR'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterAdminScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Register sebagai Karyawan'),
              subtitle: const Text('Memerlukan token undangan dari admin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}