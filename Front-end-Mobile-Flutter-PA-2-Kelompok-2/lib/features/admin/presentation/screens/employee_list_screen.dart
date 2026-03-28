import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/models/app_user.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _repo = AuthRepository();
  bool _loading = true;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _users = await _repo.getCompanyEmployees();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetDevice(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Perangkat'),
        content: Text(
          'Akun "${user.name.isEmpty ? user.email : user.name}" akan direset perangkatnya.\n\n'
          'Gunakan ini jika pengguna telah menginstal ulang aplikasi dan tidak bisa masuk karena perangkat berbeda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repo.resetDeviceBinding(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perangkat "${user.name.isEmpty ? user.email : user.name}" berhasil direset. Pengguna dapat login kembali.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Karyawan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Tidak ada karyawan aktif.'))
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(item.name.isEmpty ? item.email : item.name),
                      subtitle: Text('${item.email}\n${item.phone}'),
                      isThreeLine: true,
                      trailing: Tooltip(
                        message: 'Reset Perangkat',
                        child: IconButton(
                          icon: const Icon(Icons.smartphone, color: Colors.orange),
                          onPressed: () => _resetDevice(item),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
