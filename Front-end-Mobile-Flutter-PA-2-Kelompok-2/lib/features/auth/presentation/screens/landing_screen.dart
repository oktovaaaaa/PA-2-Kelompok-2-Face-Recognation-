import 'package:flutter/material.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../admin/presentation/screens/login_screen.dart';
import 'register_choice_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center, size: 88),
            const SizedBox(height: 20),
            const Text(
              'Sistem absensi',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ikan hiu makan tomat,  silahkan login',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              title: 'Login',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterChoiceScreen()),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}