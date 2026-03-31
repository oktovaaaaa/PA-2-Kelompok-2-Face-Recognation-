// lib/features/admin/presentation/screens/employee_stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front_end/core/network/api_client.dart';
import 'package:front_end/core/utils/error_mapper.dart';

class EmployeeStatsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const EmployeeStatsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<EmployeeStatsScreen> createState() => _EmployeeStatsScreenState();
}

class _EmployeeStatsScreenState extends State<EmployeeStatsScreen> {
  bool _loading = false;
  List<dynamic> _records = [];
  Map<String, int> _stats = {'PRESENT': 0, 'LATE': 0, 'ABSENT': 0, 'LEAVE': 0, 'SICK': 0};
  String _filter = 'month';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      // Re-use the existing endpoint with user_id filter
      final res = await ApiClient.get('/api/admin/attendance?filter=$_filter&user_id=${widget.userId}');
      if (res.success && mounted) {
        final List<dynamic> data = res.data ?? [];
        _records = data;
        
        // Reset stats
        _stats = {'PRESENT': 0, 'LATE': 0, 'ABSENT': 0, 'LEAVE': 0, 'SICK': 0};
        
        for (var r in data) {
          final status = (r['status'] ?? '').toString().toUpperCase();
          if (_stats.containsKey(status)) {
            _stats[status] = (_stats[status] ?? 0) + 1;
          }
        }
        setState(() {});
      }
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
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
                      Expanded(
                        child: Text(
                          'Statistik Karyawan',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        child: Text(
                          widget.userName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('ID: ${widget.userId.substring(0, 8)}...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Filter
                        _buildFilterRow(),
                        const SizedBox(height: 24),

                        // Stats Summary
                        _buildStatsSummary(),
                        const SizedBox(height: 24),

                        // History Header
                        const Text('Riwayat Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),
                        
                        if (_records.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            child: Center(child: Text('Tidak ada data untuk periode ini.', style: TextStyle(color: Colors.grey.shade500))),
                          )
                        else
                          ..._records.map((r) => _buildRecordItem(r)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _filterBtn('week', 'Minggu'),
        const SizedBox(width: 8),
        _filterBtn('month', 'Bulan'),
        const SizedBox(width: 8),
        _filterBtn('year', 'Tahun'),
      ],
    );
  }

  Widget _filterBtn(String f, String label) {
    final active = _filter == f;
    return InkWell(
      onTap: () {
        setState(() => _filter = f);
        _loadStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFF2563EB) : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey.shade600, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final total = _stats.values.reduce((a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: total == 0 
              ? const Center(child: Text('N/A'))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      if (_stats['PRESENT']! > 0) PieChartSectionData(value: _stats['PRESENT']!.toDouble(), color: Colors.green, radius: 25, showTitle: false),
                      if (_stats['LATE']! > 0) PieChartSectionData(value: _stats['LATE']!.toDouble(), color: Colors.orange, radius: 25, showTitle: false),
                      if (_stats['ABSENT']! > 0) PieChartSectionData(value: _stats['ABSENT']!.toDouble(), color: Colors.red, radius: 25, showTitle: false),
                      if (_stats['LEAVE']! > 0 || _stats['SICK']! > 0) PieChartSectionData(value: (_stats['LEAVE']! + _stats['SICK']!).toDouble(), color: Colors.blue, radius: 25, showTitle: false),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBit(Colors.green, 'Hadir', _stats['PRESENT']!),
              _statBit(Colors.orange, 'Telat', _stats['LATE']!),
              _statBit(Colors.red, 'Alpha', _stats['ABSENT']!),
              _statBit(Colors.blue, 'Izin', (_stats['LEAVE']! + _stats['SICK']!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBit(Color color, String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> r) {
    final status = (r['status'] ?? '').toString().toUpperCase();
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'PRESENT': statusColor = Colors.green; statusLabel = 'Hadir'; break;
      case 'LATE': statusColor = Colors.orange; statusLabel = 'Terlambat'; break;
      case 'ABSENT': statusColor = Colors.red; statusLabel = 'Alpha'; break;
      case 'LEAVE': statusColor = Colors.blue; statusLabel = 'Izin'; break;
      case 'SICK': statusColor = Colors.purple; statusLabel = 'Sakit'; break;
      default: statusColor = Colors.grey; statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['date'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                '${r['check_in_time']?.toString().substring(11, 16) ?? '--:--'} - ${r['check_out_time']?.toString().substring(11, 16) ?? '--:--'}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
