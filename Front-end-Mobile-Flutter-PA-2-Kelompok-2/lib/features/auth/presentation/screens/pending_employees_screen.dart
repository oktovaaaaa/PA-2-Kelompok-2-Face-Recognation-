// lib/features/admin/presentation/screens/pending_employees_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/models/app_user.dart';

class PendingEmployeesScreen extends StatefulWidget {
  const PendingEmployeesScreen({super.key});

  @override
  State<PendingEmployeesScreen> createState() => _PendingEmployeesScreenState();
}

class _PendingEmployeesScreenState extends State<PendingEmployeesScreen> {
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
      _users = await _repo.getPendingEmployees();
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(String userId) async {
    try {
      await _repo.approveEmployee(userId);
      await _load();
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _reject(String userId) async {
    try {
      await _repo.rejectEmployee(userId);
      await _load();
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Employees'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Tidak ada karyawan pending.'))
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _users[index];
                    return ListTile(
                      title: Text(item.name.isEmpty ? item.email : item.name),
                      subtitle: Text(item.email),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => _approve(item.id),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () => _reject(item.id),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}