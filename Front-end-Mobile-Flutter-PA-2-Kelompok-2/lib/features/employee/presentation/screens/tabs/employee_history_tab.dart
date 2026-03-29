// lib/features/employee/presentation/screens/tabs/employee_history_tab.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/network/api_client.dart';

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

    return Column(
      children: [
        // Filter pills
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (final f in [('week', 'Minggu Ini'), ('month', 'Bulan Ini'), ('year', 'Tahun Ini')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: _filter == f.$1,
                    onSelected: (_) { setState(() => _filter = f.$1); _load(); },
                    selectedColor: const Color(0xFF2E7D32),
                    labelStyle: TextStyle(
                      color: _filter == f.$1 ? Colors.white : Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Pie chart statistik
                    if (total > 0)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('Statistik Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 150,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      if (present > 0) PieChartSectionData(value: present.toDouble(), color: Colors.green, title: '$present', radius: 50),
                                      if (absent > 0) PieChartSectionData(value: absent.toDouble(), color: Colors.red, title: '$absent', radius: 50),
                                      if (leave > 0) PieChartSectionData(value: leave.toDouble(), color: Colors.orange, title: '$leave', radius: 50),
                                      if (sick > 0) PieChartSectionData(value: sick.toDouble(), color: Colors.blue, title: '$sick', radius: 50),
                                    ],
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _legendItem(Colors.green, 'Hadir', present),
                                  _legendItem(Colors.red, 'Alpha', absent),
                                  _legendItem(Colors.orange, 'Izin', leave),
                                  _legendItem(Colors.blue, 'Sakit', sick),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // List records
                    if (_records.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('Tidak ada riwayat', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    else
                      ...(_records.map((r) {
                        final rec = r as Map<String, dynamic>;
                        final status = rec['status'] ?? '';
                        final color = _statusColor(status);
                        final checkIn = rec['check_in_time']?.toString().isNotEmpty == true
                            ? rec['check_in_time'].toString().substring(11, 19) : '-';
                        final checkOut = rec['check_out_time']?.toString().isNotEmpty == true
                            ? rec['check_out_time'].toString().substring(11, 19) : '-';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                              child: Icon(Icons.calendar_today_rounded, color: color, size: 20),
                            ),
                            title: Text(rec['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Masuk: $checkIn  •  Pulang: $checkOut',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            trailing: Chip(
                              label: Text(_statusLabel(status),
                                  style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: color,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        );
                      })),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Column(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
