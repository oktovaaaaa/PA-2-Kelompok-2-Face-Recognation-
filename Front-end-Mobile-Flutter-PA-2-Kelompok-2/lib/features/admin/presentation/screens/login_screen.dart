import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/error_mapper.dart';
import 'admin_dashboard_screen.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../auth/data/auth_repository.dart';
import 'otp_login_screen.dart';
import 'splash_gate.dart';

class LoginScreen extends StatefulWidget {
  final bool pinOnlyMode;
  const LoginScreen({super.key, this.pinOnlyMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _repo = AuthRepository();
  final _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();

  bool _loading = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      setState(() {});
      if (widget.pinOnlyMode && _canCheckBiometrics) {
        _authenticateBiometrics();
      }
    } catch (_) {}
  }

  Future<void> _authenticateBiometrics() async {
    if (!_canCheckBiometrics) return;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan biometrik untuk login cepat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Provider.of<AuthProvider>(context, listen: false).unlockSession();

          if (widget.pinOnlyMode) return; // In lockscreen, just unlock

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashGate()),
            (_) => false,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _repo.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpLoginScreen(email: _email.text.trim()),
        ),
      );
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);
    try {
      final authData = await _repo.getGoogleAuthData();
      if (authData == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final idToken = authData['idToken']!;
      final email = authData['email']!;

      await _repo.googleLogin(idToken);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Google diproses, periksa email Anda untuk OTP.')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpLoginScreen(email: email),
        ),
      );
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginPin() async {
    if (_pin.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN harus 6 digit.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _repo.loginPin(_pin.text.trim());
      if (!mounted) return;
      Provider.of<AuthProvider>(context, listen: false).unlockSession();

      if (widget.pinOnlyMode) return; // In lockscreen, just unlock

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashGate()),
        (_) => false,
      );
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final pinOnly = widget.pinOnlyMode;

    return Scaffold(
      appBar: AppBar(title: Text(pinOnly ? 'Login PIN' : 'Login')),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: pinOnly
            ? Column(
                children: [
                  Pinput(
                    controller: _pin,
                    length: 6,
                    obscureText: true,
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
                  const SizedBox(height: 32),
                  PrimaryButton(
                    title: 'Buka Kunci',
                    onPressed: _loginPin,
                    loading: _loading,
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      obscure: true,
                      validator: _required,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      title: 'Login via Email',
                      onPressed: _loginEmail,
                      loading: _loading,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _loginGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      label: const Text('Login dengan Google'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}