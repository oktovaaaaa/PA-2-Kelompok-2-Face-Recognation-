import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import '../../../admin/presentation/screens/login_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _repo = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _phone = TextEditingController();
  final _birthPlace = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();

  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyPhone = TextEditingController();

  bool _loading = false;
  String? _googleIdToken;

  final _dateFormatter = MaskTextInputFormatter(
    mask: '##-##-####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  Future<void> _fetchGoogleData() async {
    try {
      final authData = await _repo.getGoogleAuthData();
      if (authData != null) {
        setState(() {
          _googleIdToken = authData['idToken'];
          _email.text = authData['email']!;
          _name.text = authData['name']!;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Google tertaut. Lanjutkan mengisi data.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghubungkan Google: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _repo.registerAdmin(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        pin: _pin.text,
        phone: _phone.text.trim(),
        birthPlace: _birthPlace.text.trim(),
        birthDate: _birthDate.text.trim(),
        address: _address.text.trim(),
        companyName: _companyName.text.trim(),
        companyAddress: _companyAddress.text.trim(),
        companyEmail: _companyEmail.text.trim(),
        companyPhone: _companyPhone.text.trim(),
        googleIdToken: _googleIdToken,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi admin berhasil. Silakan login.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Admin')),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_googleIdToken == null) ...[
                OutlinedButton.icon(
                  onPressed: _fetchGoogleData,
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                  label: const Text('Isi otomatis dengan Google'),
                ),
                const SizedBox(height: 16),
              ],
              AppTextField(controller: _name, label: 'Nama lengkap', validator: _required),
              const SizedBox(height: 12),
              AppTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress, validator: _required),
              const SizedBox(height: 12),
              AppTextField(controller: _password, label: 'Password', obscure: true, validator: _required),
              const SizedBox(height: 12),
              AppTextField(
                controller: _pin,
                label: 'PIN 6 digit',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'PIN wajib diisi';
                  if (v.length != 6) return 'PIN harus 6 digit';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _phone, label: 'Nomor Telepon', keyboardType: TextInputType.phone, validator: _required),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(child: AppTextField(controller: _birthPlace, label: 'Tempat Lahir', validator: _required)),
                   const SizedBox(width: 12),
                   Expanded(
                     child: AppTextField(
                       controller: _birthDate, 
                       label: 'Tgl Lahir (DD-MM-YYYY)', 
                       keyboardType: TextInputType.number,
                       inputFormatters: [_dateFormatter],
                       validator: _required,
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _address, label: 'Alamat Pribadi', validator: _required),
              
              const Divider(height: 48, thickness: 2),
              const Text('Data Perusahaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              AppTextField(controller: _companyName, label: 'Nama Perusahaan', validator: _required),
              const SizedBox(height: 12),
              AppTextField(controller: _companyEmail, label: 'Email Perusahaan', keyboardType: TextInputType.emailAddress, validator: _required),
              const SizedBox(height: 12),
              AppTextField(controller: _companyPhone, label: 'Telepon Perusahaan', keyboardType: TextInputType.phone, validator: _required),
              const SizedBox(height: 12),
              AppTextField(controller: _companyAddress, label: 'Alamat Perusahaan', validator: _required),
              const SizedBox(height: 24),

              PrimaryButton(title: 'Daftar Admin', onPressed: _submit, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}