import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/error_mapper.dart';
import 'splash_gate.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../auth/data/auth_repository.dart';

class OtpLoginScreen extends StatefulWidget {
  final String email;
  const OtpLoginScreen({super.key, required this.email});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _repo = AuthRepository();
  final _otp = TextEditingController();
  bool _loading = false;

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await _repo.verifyLoginOtp(
        email: widget.email,
        code: _otp.text.trim(),
      );

      if (!mounted) return;
      
      // Delegasikan ke SplashGate agar routing handling menjadi seragam (admin maupun employee)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashGate()),
        (_) => false,
      );
      
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP Login'),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Masukkan OTP yang dikirim ke ${widget.email}'),
            const SizedBox(height: 16),
            Pinput(
              controller: _otp,
              length: 6,
              keyboardType: TextInputType.number,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4D64F5), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              title: 'Verifikasi',
              onPressed: _verify,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}