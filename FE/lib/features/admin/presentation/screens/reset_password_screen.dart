import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:front_end/features/common/widgets/app_dialog.dart';
import 'package:front_end/features/common/widgets/app_text_field.dart';
import 'package:front_end/features/common/widgets/wavy_background.dart';
import 'package:front_end/core/utils/error_mapper.dart';
import 'package:front_end/features/auth/data/auth_repository.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _repo = AuthRepository();
  bool _loading = false;

  Future<void> _submit() async {
    final otp = _otp.text.trim();
    final pass = _newPassword.text;
    final confirm = _confirmPassword.text;

    if (otp.length != 6) {
      AppDialog.showError(context, 'OTP harus 6 digit');
      return;
    }
    if (pass.isEmpty) {
      AppDialog.showError(context, 'Kata sandi baru wajib diisi');
      return;
    }
    if (pass != confirm) {
      AppDialog.showError(context, 'Konfirmasi kata sandi tidak cocok');
      return;
    }

    setState(() => _loading = true);
    try {
      await _repo.resetPassword(
        email: widget.email,
        code: otp,
        newPassword: pass,
      );
      if (!mounted) return;
      AppDialog.showSuccess(context, 'Kata sandi berhasil diperbarui. Silakan login.');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppDialog.showError(context, ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WavyBackground(
      isAuth: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.verified_user_rounded, color: Colors.white, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Atur Ulang Sandi',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Identitas Anda berhasil dikonfirmasi.\nSilakan buat kata sandi baru yang aman.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.4),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    const Text('Masukan Kode OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Pinput(
                      controller: _otp,
                      length: 6,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      defaultPinTheme: PinTheme(
                        width: 45,
                        height: 50,
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 45,
                        height: 50,
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF2563EB), width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppTextField(controller: _newPassword, label: 'Kata Sandi Baru', obscure: true),
                    const SizedBox(height: 16),
                    AppTextField(controller: _confirmPassword, label: 'Konfirmasi Sandi', obscure: true),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Reset Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
