// lib/features/employee/presentation/screens/tabs/employee_history_tab.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/network/api_client.dart';
import 'package:flutter/services.dart';

class EmployeeHistoryTab extends StatefulWidget {
  const EmployeeHistoryTab({super.key});

  @override
  State<EmployeeHistoryTab> createState() => _EmployeeHistoryTabState();
}

class _EmployeeHistoryTabState extends State<EmployeeHistoryTab> {
  String _filter = 'month';
  List<dynamic> _records = [];
  Map<String, dynamic>? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/employee/attendance/history?filter=$_filter');
      if (res.success && mounted) {
        setState(() {
          _records = res.data?['records'] ?? [];
          _stats = res.data?['stats'] as Map<String, dynamic>?;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PRESENT': return Colors.green;
      case 'ABSENT': return Colors.red;
      case 'LEAVE': return Colors.orange;
      case 'SICK': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PRESENT': return 'Hadir';
      case 'ABSENT': return 'Alpha';
      case 'LEAVE': return 'Izin';
      case 'SICK': return 'Sakit';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _stats?['present'] ?? 0;
    final absent = _stats?['absent'] ?? 0;
    final leave = _stats?['leave'] ?? 0;
    final sick = _stats?['sick'] ?? 0;
    final total = _stats?['total'] ?? 0;
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
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 0),
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
                    'Riwayat Presensi',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lacak performa kehadiran Anda',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
                  ),
                  const SizedBox(height: 24),
                  // Premium Filter Pills inside header
                  Row(
                    children: [
                      for (final f in [('week', 'Minggu'), ('month', 'Bulan'), ('year', 'Tahun')])
                        Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 20),
                          child: GestureDetector(
                            onTap: () { setState(() => _filter = f.$1); _load(); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _filter == f.$1 ? Colors.white : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                f.$2,
                                style: TextStyle(
                                  color: _filter == f.$1 ? const Color(0xFF1E3A8A) : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFF2563EB),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      children: [
                        // Pie Chart Card Premium
                        if (total > 0)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.pie_chart_rounded, color: Color(0xFF2563EB), size: 20),
                                    SizedBox(width: 8),
                                    Text('Statistik Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  height: 160,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        if (present > 0) PieChartSectionData(value: present.toDouble(), color: const Color(0xFF2E7D32), title: '$present', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if (absent > 0) PieChartSectionData(value: absent.toDouble(), color: const Color(0xFFDC2626), title: '$absent', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if (leave > 0) PieChartSectionData(value: leave.toDouble(), color: const Color(0xFFD97706), title: '$leave', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        if (sick > 0) PieChartSectionData(value: sick.toDouble(), color: const Color(0xFF2563EB), title: '$sick', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _legendItem(const Color(0xFF2E7D32), 'Hadir', present),
                                    _legendItem(const Color(0xFFDC2626), 'Alpha', absent),
                                    _legendItem(const Color(0xFFD97706), 'Izin', leave),
                                    _legendItem(const Color(0xFF2563EB), 'Sakit', sick),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        const Text('Detail Riwayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                        const SizedBox(height: 16),
                        if (_records.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 32),
                                Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('Belum ada riwayat', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        else
                          ...(_records.map((r) {
                            final rec = r as Map<String, dynamic>;
                            final status = rec['status'] ?? '';
                            final color = _statusColor(status);
                            final checkIn = rec['check_in_time']?.toString().isNotEmpty == true
                                ? rec['check_in_time'].toString().substring(11, 16) : '--:--';
                            final checkOut = rec['check_out_time']?.toString().isNotEmpty == true
                                ? rec['check_out_time'].toString().substring(11, 16) : '--:--';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.event_available_rounded, color: color, size: 22),
                                ),
                                title: Text(rec['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                subtitle: Text('$checkIn - $checkOut', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_statusLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            );
                          })),
                      ],
                    ),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($count)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
