// lib/features/employee/presentation/screens/tabs/employee_leave_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';

class EmployeeLeaveTab extends StatefulWidget {
  const EmployeeLeaveTab({super.key});

  @override
  State<EmployeeLeaveTab> createState() => _EmployeeLeaveTabState();
}

class _EmployeeLeaveTabState extends State<EmployeeLeaveTab> {
  List<dynamic> _leaves = [];
  bool _loading = false;

  final _statusColors = {
    'PENDING': Colors.orange,
    'APPROVED': Colors.green,
    'REJECTED': Colors.red,
  };
  final _statusLabels = {
    'PENDING': 'Menunggu',
    'APPROVED': 'Disetujui',
    'REJECTED': 'Ditolak',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/employee/leaves');
      if (res.success && mounted) setState(() => _leaves = res.data ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    String selectedType = existing?['type'] ?? 'IZIN';
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    bool confirmed = false;
    File? pickedPhoto;
    String? uploadedPhotoUrl = existing?['photo_url'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Izin' : 'Ajukan Izin/Sakit',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                // Tipe
                Row(
                  children: [
                    for (final t in ['IZIN', 'SAKIT'])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: t == 'IZIN' ? 8.0 : 0),
                          child: ChoiceChip(
                            label: Text(t == 'IZIN' ? '📄 Izin' : '🏥 Sakit'),
                            selected: selectedType == t,
                            onSelected: (_) => setModal(() => selectedType = t),
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(color: selectedType == t ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul Izin',
                    hintText: 'contoh: Izin Pernikahan Saudara',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    hintText: 'Jelaskan alasan izin...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Upload foto bukti
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (picked != null) setModal(() => pickedPhoto = File(picked.path));
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: pickedPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(pickedPhoto!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : uploadedPhotoUrl != null && uploadedPhotoUrl!.isNotEmpty
                            ? Center(child: Text('📷 Foto sudah ada', style: TextStyle(color: Colors.grey.shade600)))
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded, color: Colors.grey.shade400, size: 32),
                                    Text('Tambah Foto Bukti (opsional)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 12),
                // Checkbox konfirmasi
                CheckboxListTile(
                  value: confirmed,
                  onChanged: (v) => setModal(() => confirmed = v ?? false),
                  title: const Text('Saya menyatakan bahwa data izin ini adalah benar dan tidak dipalsu.',
                      style: TextStyle(fontSize: 13)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Upload foto jika ada
                      if (pickedPhoto != null) {
                        final uploadRes = await ApiClient.uploadFile(pickedPhoto!);
                        if (uploadRes.success) {
                          uploadedPhotoUrl = uploadRes.data?['url'] as String?;
                        }
                      }
                      final body = {
                        'type': selectedType,
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'photo_url': uploadedPhotoUrl ?? '',
                        'confirmed_honest': confirmed,
                      };
                      try {
                        final res = isEdit
                            ? await ApiClient.put('/api/employee/leaves/${existing!['id']}', body)
                            : await ApiClient.post('/api/employee/leaves', body);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res.success
                              ? (isEdit ? 'Izin diperbarui' : 'Izin berhasil diajukan!')
                              : (res.message ?? 'Gagal')),
                          backgroundColor: res.success ? Colors.green : Colors.red,
                        ));
                        if (res.success) _load();
                      } catch (_) {}
                    },
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Ajukan Izin'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLeave(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Riwayat Izin', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Hapus dari riwayat kamu? Admin masih dapat melihat data ini.'),
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
      final res = await ApiClient.delete('/api/employee/leaves/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success ? 'Dihapus dari riwayat kamu' : (res.message ?? 'Gagal')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ));
      if (res.success) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Izin'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leaves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Belum ada pengajuan izin', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _leaves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final l = _leaves[i] as Map<String, dynamic>;
                      final status = l['status'] ?? '';
                      final color = _statusColors[status] ?? Colors.grey;
                      final isPending = status == 'PENDING';
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                            child: Icon(l['type'] == 'SAKIT' ? Icons.sick_rounded : Icons.event_busy_rounded,
                                color: color),
                          ),
                          title: Text(l['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(l['type'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(_statusLabels[status] ?? status,
                                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                                backgroundColor: color,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _showForm(existing: l);
                                  if (v == 'delete') _deleteLeave(l['id']);
                                },
                                itemBuilder: (_) => [
                                  if (isPending)
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                ],
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
