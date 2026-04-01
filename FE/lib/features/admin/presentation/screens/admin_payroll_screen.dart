// lib/features/admin/presentation/screens/admin_payroll_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../common/widgets/app_dialog.dart';
import '../../../../core/constants/app_constants.dart';

class AdminPayrollScreen extends StatefulWidget {
  final bool isTab;
  const AdminPayrollScreen({super.key, this.isTab = false});

  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  List<dynamic> _salaries = [];
  List<dynamic> _positions = [];
  bool _loading = false;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedPositionId;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPositions();
    _loadSalaries();
  }

  Future<void> _loadPositions() async {
    final res = await ApiClient.get('/api/admin/positions');
    if (res.success && mounted) {
      setState(() => _positions = res.data ?? []);
    }
  }

  Future<void> _loadSalaries() async {
    setState(() => _loading = true);
    try {
      String url = '/api/admin/payroll?month=$_selectedMonth&year=$_selectedYear';
      if (_selectedPositionId != null) url += '&position_id=$_selectedPositionId';
      if (_searchCtrl.text.isNotEmpty) url += '&search=${_searchCtrl.text}';

      final res = await ApiClient.get(url);
      if (res.success && mounted) {
        setState(() => _salaries = res.data ?? []);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${NumberFormat.decimalPattern('id').format(amount)}';
  }

  void _showPaymentDialog(Map<String, dynamic> salary) async {
    final user = salary['user'] as Map<String, dynamic>;
    File? proofImage;
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Anda akan membayar gaji untuk ${user['name']}', style: TextStyle(color: Colors.grey.shade600)),
              const Divider(height: 32),
              
              // Bank Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['bank_name'] ?? 'Bank Belum Diatur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(user['bank_account_number'] ?? '-', style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 15, letterSpacing: 1.2)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Bukti Transfer (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setModalState(() => proofImage = File(picked.path));
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                  ),
                  child: proofImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(proofImage!, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: Colors.grey.shade400),
                            const SizedBox(height: 4),
                            Text('Unggah Bukti', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Konfirmasi Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((confirmed) async {
       if (confirmed == true) {
         _processPayment(salary['id'], proofImage);
       }
    });
  }

  Future<void> _processPayment(String id, File? proof) async {
    AppDialog.showLoading(context, message: 'Sedang memproses...');
    try {
      final res = await ApiClient.postMultipart(
        '/api/admin/payroll/$id/pay',
        files: proof != null ? {'proof': proof} : null,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (res.success) {
        AppDialog.showSuccess(context, 'Pembayaran berhasil dikonfirmasi');
        _loadSalaries();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal memproses pembayaran');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppDialog.showError(context, 'Terjadi kesalahan sistem');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 20),
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
                  Row(
                    children: [
                      if (!widget.isTab)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      const Text(
                        'Manajemen Gaji',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filters inside header
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                         _filterChip(
                           label: '${_monthName(_selectedMonth)} $_selectedYear',
                           icon: Icons.calendar_today_rounded,
                           onTap: _showMonthYearPicker,
                         ),
                         const SizedBox(width: 8),
                         _filterChip(
                           label: _selectedPositionId == null ? 'Semua Jabatan' : _getPositionName(_selectedPositionId!),
                           icon: Icons.work_outline_rounded,
                           onTap: _showPositionPicker,
                         ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => _loadSalaries(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama karyawan...',
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _salaries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payments_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Data payroll tidak ditemukan', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSalaries,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                            itemCount: _salaries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (_, i) {
                              final s = _salaries[i] as Map<String, dynamic>;
                              final user = s['user'] as Map<String, dynamic>;
                              final pos = user['position'] as Map<String, dynamic>?;
                              final isPaid = s['status'] == 'PAID';
                              final total = (s['total_salary'] as num).toDouble();

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                            backgroundImage: (user['photo_url'] != null && (user['photo_url'] as String).isNotEmpty)
                                                ? NetworkImage('${AppConstants.baseUrl}${user['photo_url']}')
                                                : null,
                                            child: (user['photo_url'] == null || (user['photo_url'] as String).isEmpty)
                                                ? Text(user['name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                Text(pos?['name'] ?? 'Staf', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isPaid ? 'Lunas' : 'Pending',
                                              style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 32),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Total Gaji', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                              const SizedBox(height: 2),
                                              Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                                            ],
                                          ),
                                          if (!isPaid)
                                            ElevatedButton(
                                              onPressed: () => _showPaymentDialog(s),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2563EB),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              child: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                                            )
                                          else
                                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
                                        ],
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
      ),
    );
  }

  Widget _filterChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _showMonthYearPicker() async {
     await showModalBottomSheet(
       context: context,
       builder: (ctx) => Container(
         padding: const EdgeInsets.all(24),
         height: 300,
         child: Column(
           children: [
             const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const Expanded(child: SizedBox()),
             Row(
               children: [
                 Expanded(
                   child: DropdownButton<int>(
                     isExpanded: true,
                     value: _selectedMonth,
                     items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(_monthName(i+1)))),
                     onChanged: (v) { _selectedMonth = v!; Navigator.pop(ctx); _loadSalaries(); },
                   ),
                 ),
                 const SizedBox(width: 16),
                  Expanded(
                   child: DropdownButton<int>(
                     isExpanded: true,
                     value: _selectedYear,
                     items: List.generate(5, (i) => DropdownMenuItem(value: DateTime.now().year - i, child: Text('${DateTime.now().year - i}'))),
                     onChanged: (v) { _selectedYear = v!; Navigator.pop(ctx); _loadSalaries(); },
                   ),
                 ),
               ],
             ),
             const Expanded(child: SizedBox()),
           ],
         ),
       ),
     );
  }

  void _showPositionPicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Jabatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Semua Jabatan'),
              onTap: () { setState(() => _selectedPositionId = null); Navigator.pop(ctx); _loadSalaries(); },
            ),
            ...(_positions.map((p) => ListTile(
              title: Text(p['name']),
              onTap: () { setState(() => _selectedPositionId = p['id']); Navigator.pop(ctx); _loadSalaries(); },
            ))),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    return ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][m-1];
  }

  String _getPositionName(String id) {
    final p = _positions.firstWhere((element) => element['id'] == id, orElse: () => null);
    return p != null ? p['name'] : 'Semua Jabatan';
  }
}
