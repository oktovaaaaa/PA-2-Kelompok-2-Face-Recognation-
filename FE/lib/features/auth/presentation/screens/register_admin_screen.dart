import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/wavy_background.dart';
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
    filter: {"#": RegExp(r'[0-9]')},
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghubungkan Google: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Widget _buildSectionCard({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WavyBackground(
      isAuth: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Daftar Admin', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text('Lengkapi data diri dan perusahaan Anda', style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_googleIdToken == null) ...[
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _fetchGoogleData,
                      icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF0F172A)),
                      label: const Text('Isi otomatis dari Google', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionCard(
                    title: 'Data Pribadi',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF2563EB),
                    children: [
                      AppTextField(controller: _name, label: 'Full Name', validator: _required),
                      const SizedBox(height: 16),
                      AppTextField(controller: _email, label: 'Enter Email', keyboardType: TextInputType.emailAddress, validator: _required),
                      const SizedBox(height: 16),
                      AppTextField(controller: _password, label: 'Enter Password', obscure: true, validator: _required),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _pin,
                        label: 'PIN Keamanan (6 Digit)',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'PIN wajib diisi';
                          if (v.length != 6) return 'PIN harus 6 digit';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(controller: _phone, label: 'Nomor Telepon', keyboardType: TextInputType.phone, validator: _required),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: AppTextField(controller: _birthPlace, label: 'Tempat Lahir', validator: _required)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _birthDate,
                              label: 'Tgl (DD-MM-YYYY)',
                              keyboardType: TextInputType.number,
                              inputFormatters: [_dateFormatter],
                              validator: _required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(controller: _address, label: 'Alamat', validator: _required),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Data Perusahaan',
                    icon: Icons.business_rounded,
                    color: const Color(0xFF1E3A8A),
                    children: [
                      AppTextField(controller: _companyName, label: 'Nama Perusahaan', validator: _required),
                      const SizedBox(height: 16),
                      AppTextField(controller: _companyEmail, label: 'Email Perusahaan', keyboardType: TextInputType.emailAddress, validator: _required),
                      const SizedBox(height: 16),
                      AppTextField(controller: _companyPhone, label: 'Telepon Perusahaan', keyboardType: TextInputType.phone, validator: _required),
                      const SizedBox(height: 16),
                      AppTextField(controller: _companyAddress, label: 'Alamat Kantor', validator: _required),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2))
                          : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}