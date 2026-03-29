// lib/features/admin/presentation/screens/tabs/admin_position_tab.dart

import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';

class AdminPositionTab extends StatefulWidget {
  const AdminPositionTab({super.key});

  @override
  State<AdminPositionTab> createState() => _AdminPositionTabState();
}

class _AdminPositionTabState extends State<AdminPositionTab> {
  List<dynamic> _positions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/admin/positions');
      if (res.success && mounted) setState(() => _positions = res.data ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final salaryCtrl = TextEditingController(
        text: existing?['salary'] != null ? existing!['salary'].toString() : '');
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Jabatan' : 'Tambah Jabatan',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Jabatan',
                hintText: 'contoh: Manager, Staff, Supervisor',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: salaryCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Gaji Pokok (Rp)',
                hintText: 'contoh: 5000000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D64F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final body = {
                    'name': nameCtrl.text.trim(),
                    'salary': double.tryParse(salaryCtrl.text.trim()) ?? 0.0,
                  };
                  try {
                    if (isEdit) {
                      await ApiClient.put('/api/admin/positions/${existing!['id']}', body);
                    } else {
                      await ApiClient.post('/api/admin/positions', body);
                    }
                    _loadPositions();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Jabatan diperbarui' : 'Jabatan ditambahkan'),
                            backgroundColor: Colors.green),
                      );
                    }
                  } catch (_) {}
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Jabatan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePosition(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jabatan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus jabatan "$name"? Jabatan yang masih digunakan karyawan tidak dapat dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await ApiClient.delete('/api/admin/positions/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success ? 'Jabatan dihapus' : (res.message ?? 'Gagal menghapus jabatan')),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ),
      );
      if (res.success) _loadPositions();
    } catch (_) {}
  }

  String _formatSalary(dynamic salary) {
    if (salary == null) return 'Rp 0';
    final val = (salary as num).toDouble();
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF4D64F5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jabatan'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _positions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_outline_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Belum ada jabatan', style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Tap tombol + untuk menambah', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPositions,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _positions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = _positions[i] as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4D64F5).withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.work_rounded, color: Color(0xFF4D64F5)),
                          ),
                          title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(_formatSalary(p['salary']),
                              style: const TextStyle(color: Color(0xFF4D64F5), fontWeight: FontWeight.w500)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                onPressed: () => _showForm(existing: p),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                onPressed: () => _deletePosition(p['id'], p['name']),
                                tooltip: 'Hapus',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
