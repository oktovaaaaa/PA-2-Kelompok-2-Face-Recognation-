import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/primary_button.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _repo = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _repo.getCompanySettings();
      _name.text = res['name'] ?? '';
      _email.text = res['email'] ?? '';
      _phone.text = res['phone'] ?? '';
      _address.text = res['address'] ?? '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repo.updateCompanySettings({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan Perusahaan berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Perusahaan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppTextField(controller: _name, label: 'Nama Perusahaan', validator: _required),
                  const SizedBox(height: 12),
                  AppTextField(controller: _email, label: 'Email Perusahaan', keyboardType: TextInputType.emailAddress, validator: _required),
                  const SizedBox(height: 12),
                  AppTextField(controller: _phone, label: 'Telepon Perusahaan', keyboardType: TextInputType.phone, validator: _required),
                  const SizedBox(height: 12),
                  AppTextField(controller: _address, label: 'Alamat Perusahaan', validator: _required),
                  const SizedBox(height: 24),
                  PrimaryButton(title: 'Simpan', onPressed: _save, loading: _saving),
                ],
              ),
            ),
    );
  }
}
