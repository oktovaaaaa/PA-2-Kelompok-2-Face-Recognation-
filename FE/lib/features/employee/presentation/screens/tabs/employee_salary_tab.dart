// lib/features/employee/presentation/screens/tabs/employee_salary_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/network/api_client.dart';
import 'package:intl/intl.dart';

class EmployeeSalaryTab extends StatefulWidget {
  const EmployeeSalaryTab({super.key});

  @override
  State<EmployeeSalaryTab> createState() => _EmployeeSalaryTabState();
}

class _EmployeeSalaryTabState extends State<EmployeeSalaryTab> {
  List<dynamic> _salaries = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSalaries();
  }

  Future<void> _loadSalaries() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/employee/salaries');
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

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month < 1 || month > 12) return '-';
    return months[month - 1];
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
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 32),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Gaji',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rekapitulasi penghasilan bulanan Anda',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
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
                              Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Belum ada data gaji', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSalaries,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                            itemCount: _salaries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (_, i) {
                              final s = _salaries[i] as Map<String, dynamic>;
                              final isPaid = s['status'] == 'PAID';
                              final total = (s['total_salary'] as num).toDouble();
                              final base = (s['base_salary'] as num).toDouble();
                              final deductions = (s['deductions'] as num).toDouble();

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_getMonthName(s['month'])} ${s['year']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isPaid ? 'Sudah Dibayar' : 'Menunggu Pembayaran',
                                                style: TextStyle(
                                                  color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFEA580C),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: (isPaid ? const Color(0xFF2E7D32) : const Color(0xFFEA580C)).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                              color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFEA580C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          _buildDetailRow('Gaji Pokok', _formatCurrency(base)),
                                          const SizedBox(height: 12),
                                          _buildDetailRow('Potongan (Denda)', '- ${_formatCurrency(deductions)}', isNegative: true),
                                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Total Gaji Bersih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text(
                                                _formatCurrency(total),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2563EB)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isPaid && s['paid_at'] != null)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                                        ),
                                        child: Text(
                                          'Dibayar pada: ${s['paid_at'].toString().substring(0, 10)}',
                                          style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
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

  Widget _buildDetailRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isNegative ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
