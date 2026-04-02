// lib/features/admin/presentation/screens/penalty_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../common/widgets/app_dialog.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../common/widgets/app_text_field.dart';

class PenaltyManagementScreen extends StatefulWidget {
  const PenaltyManagementScreen({super.key});

  @override
  State<PenaltyManagementScreen> createState() => _PenaltyManagementScreenState();
}

class _PenaltyManagementScreenState extends State<PenaltyManagementScreen> {
  List<dynamic> _penalties = [];
  List<dynamic> _employees = [];
  bool _isLoading = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadEmployees();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final res = await ApiClient.get('/api/admin/penalties');
    if (res.success && mounted) {
      setState(() => _penalties = res.data ?? []);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadEmployees() async {
    final res = await ApiClient.get('/api/admin/employees?status=ACTIVE');
    if (res.success && mounted) {
      setState(() => _employees = res.data ?? []);
    }
  }

  Future<void> _deletePenalty(String id) async {
    final confirm = await AppDialog.showConfirm(
      context,
      title: 'Hapus Denda',
      message: 'Apakah Anda yakin ingin menghapus data denda ini? Gaji karyawan akan dihitung ulang.',
      confirmText: 'Hapus',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    final res = await ApiClient.delete('/api/admin/penalties/$id');
    if (res.success && mounted) {
      AppDialog.showSuccess(context, 'Denda berhasil dihapus');
      _loadData();
    }
  }

  void _showAddDialog() {
    String? selectedUserId;
    String? selectedUserName;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    File? imageFile;
    bool isSubmitting = false;

    // Searchable Picker Helper
    void _showSearchablePicker(StateSetter setModalState) {
      String searchKeyword = "";
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSearchState) => Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama karyawan...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setSearchState(() => searchKeyword = v.toLowerCase()),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: _employees
                        .where((e) => (e['name'] ?? '').toString().toLowerCase().contains(searchKeyword))
                        .map((e) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                child: Text(e['name']?[0].toUpperCase() ?? '?', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                              ),
                              title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(e['Position']?['name'] ?? 'Karyawan', style: const TextStyle(fontSize: 12)),
                              onTap: () {
                                setModalState(() {
                                  selectedUserId = e['id'].toString();
                                  selectedUserName = e['name'];
                                });
                                Navigator.pop(ctx);
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24, 
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Catat Pelanggaran & Denda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 24),
                
                const Text('Pilih Karyawan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showSearchablePicker(setModalState),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedUserName ?? 'Cari Karyawan...', style: TextStyle(color: selectedUserName == null ? Colors.grey : Colors.black87, fontSize: 14)),
                        const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(controller: titleCtrl, label: 'Judul Pelanggaran', prefixIcon: Icons.title_rounded),
                const SizedBox(height: 16),
                AppTextField(controller: descCtrl, label: 'Deskripsi (Opsional)', prefixIcon: Icons.description_outlined, maxLines: 2),
                const SizedBox(height: 16),
                AppTextField(
                  controller: amountCtrl, 
                  label: 'Nominal Denda (Rp)', 
                  prefixIcon: Icons.payments_outlined, 
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                ),
                const SizedBox(height: 20),
                
                const Text('Foto Bukti (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                    if (picked != null) {
                      setModalState(() => imageFile = File(picked.path));
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                    ),
                    child: imageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(imageFile!, fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 32),
                              SizedBox(height: 8),
                              Text('Ambil Foto Bukti', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: isSubmitting ? null : () async {
                      if (selectedUserId == null || titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                        AppDialog.showError(context, 'Harap lengkapi data wajib');
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      try {
                        // Unformat currency dots before sending to API
                        final rawAmount = CurrencyInputFormatter.unformat(amountCtrl.text);

                        final res = await ApiClient.postMultipart(
                          '/api/admin/penalties',
                          fields: {
                            'user_id': selectedUserId!,
                            'title': titleCtrl.text,
                            'description': descCtrl.text,
                            'amount': rawAmount.toString(),
                            'type': 'MANUAL',
                            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          },
                          files: imageFile != null ? {'attachment': imageFile!} : null,
                        );

                        if (res.success && mounted) {
                          Navigator.pop(ctx);
                          AppDialog.showSuccess(context, 'Denda berhasil dicatat');
                          _loadData();
                        } else {
                          if (mounted) AppDialog.showError(context, res.message ?? 'Gagal menyimpan denda');
                        }
                      } catch (e) {
                        if (mounted) AppDialog.showError(context, 'Terjadi kesalahan: $e');
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    child: isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Denda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(dynamic p) {
    final amount = (p['amount'] as num).toDouble();
    final date = DateTime.parse(p['date'] ?? DateTime.now().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                    child: Text(p['user']?['name']?[0].toUpperCase() ?? '?', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['user']?['name'] ?? 'Karyawan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(DateFormat('dd MMMM yyyy').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 48),
              const Text('Judul Pelanggaran', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(p['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
              const SizedBox(height: 24),
              const Text('Nominal Denda', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                CurrencyInputFormatter.formatNumber(amount.toInt()),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 24),
              ),
              const SizedBox(height: 24),
              const Text('Deskripsi Pelanggaran', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                p['description'] != null && p['description'].toString().isNotEmpty ? p['description'] : 'Tidak ada deskripsi tambahan',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5),
              ),
              if (p['attachment'] != null && p['attachment'].toString().isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text('Foto Bukti', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    '${AppConstants.baseUrl}${p['attachment']}',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Manajemen Denda',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_penalties.length} Pelanggaran', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Catat dan pantau pelanggaran non-absensi karyawan', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _penalties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.gavel_rounded, size: 64, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(height: 16),
                              const Text('Belum ada data denda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 8),
                              Text('Semua pelanggaran yang dicatat akan memotong gaji', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: _penalties.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (_, i) {
                              final p = _penalties[i];
                              final amount = (p['amount'] as num).toDouble();
                              final date = DateTime.parse(p['date'] ?? DateTime.now().toString());
                              final hasInisial = (p['user'] != null && p['user']['name'] != null);

                              return InkWell(
                                onTap: () => _showDetailDialog(p),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                              child: Text(
                                                hasInisial ? p['user']['name'][0].toUpperCase() : '?',
                                                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p['user']['name'] ?? 'Karyawan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                  Text(DateFormat('dd MMMM yyyy').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _deletePenalty(p['id']),
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(p['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                                Text(
                                                  '- ${CurrencyInputFormatter.formatNumber(amount.toInt())}',
                                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text('Tap untuk lihat detail pelanggaran', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Catat Pelanggaran', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
