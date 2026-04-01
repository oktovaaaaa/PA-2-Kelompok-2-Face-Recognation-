// lib/features/employee/presentation/screens/tabs/employee_leave_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import 'package:flutter/services.dart';
import '../../../../common/widgets/app_dialog.dart';

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
                      backgroundColor: const Color(0xFF2563EB),
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
                        if (!mounted) return;
                        if (res.success) {
                          AppDialog.showSuccess(context, isEdit ? 'Izin diperbarui' : 'Izin berhasil diajukan!');
                          _load();
                        } else {
                          AppDialog.showError(context, res.message ?? 'Gagal memproses izin');
                        }
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
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Hapus Riwayat Izin',
      message: 'Apakah Anda yakin ingin menghapus izin ini dari riwayat?',
      confirmText: 'Ya, Hapus',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;
    try {
      final res = await ApiClient.delete('/api/employee/leaves/$id');
      if (!mounted) return;
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, 'Dihapus dari riwayat kamu');
        _load();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal menghapus riwayat');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 4,
          highlightElevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajukan Izin', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengajuan Izin',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola ketidakhadiran Anda di sini',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
                  ),
                ],
              ),
            ),
  
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _leaves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                child: Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey.shade300),
                              ),
                              const SizedBox(height: 16),
                              Text('Belum ada pengajuan izin', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                            itemCount: _leaves.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final l = _leaves[i] as Map<String, dynamic>;
                              final status = l['status'] ?? '';
                              final color = _statusColors[status] ?? Colors.grey;
                              final isPending = status == 'PENDING';
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {}, // Detail view can be added here
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              l['type'] == 'SAKIT' ? Icons.sick_rounded : Icons.event_note_rounded,
                                              color: color,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(l['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                                const SizedBox(height: 4),
                                                Text(
                                                  l['type'] ?? '',
                                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _statusLabels[status] ?? status,
                                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 20),
                                                onSelected: (v) {
                                                  if (v == 'edit') _showForm(existing: l);
                                                  if (v == 'delete') _deleteLeave(l['id']);
                                                },
                                                itemBuilder: (_) => [
                                                  if (isPending)
                                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
                                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
