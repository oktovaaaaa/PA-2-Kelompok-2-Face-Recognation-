import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/excel_export_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../common/widgets/app_dialog.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<dynamic> _allRecords = [];
  List<dynamic> _filteredRecords = [];
  bool _loading = false;
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  
  // New Analytics State
  DateTimeRange? _selectedDateRange;
  bool _isLineChart = false;
  String _periodFilter = 'month'; // 'week', 'month', 'year', 'custom'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      String attendanceUrl = '/api/admin/attendance?filter=$_periodFilter';
      if (_periodFilter == 'custom' && _selectedDateRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        final end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
        attendanceUrl = '/api/admin/attendance?start_date=$start&end_date=$end';
      }

      final results = await Future.wait([
        ApiClient.get(attendanceUrl),
        ApiClient.get('/api/admin/leaves?status=APPROVED'),
      ]);

      final attendanceRes = results[0];
      final leavesRes = results[1];

      List<dynamic> combined = [];

      if (attendanceRes.success) {
        final List<dynamic> attData = attendanceRes.data ?? [];
        for (var item in attData) {
          combined.add(Map<String, dynamic>.from(item));
        }
      }

      if (leavesRes.success) {
        final List<dynamic> leavesData = leavesRes.data ?? [];
        // Normalize leave data to match attendance record format
        for (var leaf in leavesData) {
          final normalized = Map<String, dynamic>.from(leaf);
          combined.add({
            ...normalized,
            'date': (normalized['created_at'] ?? '').toString().substring(0, 10),
            'status': normalized['type'] ?? 'LEAVE',
            'is_leave': true,
          });
        }
      }

      if (mounted) {
        setState(() {
          _allRecords = combined;
          // Sort by date descending
          _allRecords.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          _applyFilters();
        });
      }
    } catch (_) {
      // Handle error if needed
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((r) {
        final nameMatch = (r['user_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
        final recordStatus = (r['status'] ?? r['type'] ?? '').toString().toUpperCase();
        
        bool statusMatch = _statusFilter == 'ALL';
        if (!statusMatch) {
          if (_statusFilter == 'IZIN') {
            statusMatch = recordStatus == 'IZIN' || recordStatus == 'LEAVE';
          } else if (_statusFilter == 'SAKIT') {
            statusMatch = recordStatus == 'SAKIT' || recordStatus == 'SICK';
          } else {
            statusMatch = recordStatus == _statusFilter;
          }
        }
        
        return nameMatch && statusMatch;
      }).toList();
    });
  }

  Future<void> _exportExcel() async {
    if (_filteredRecords.isEmpty) {
      AppDialog.showInfo(context, 'Tidak ada data untuk diekspor');
      return;
    }
    try {
      final path = await ExcelExportService.exportAttendance(_filteredRecords, 'Laporan_Kehadiran_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        String msg = 'Laporan berhasil dibuat';
        if (path.contains('Download')) {
          msg = 'Tersimpan di folder Download';
        }
        AppDialog.showSuccess(
          context, 
          msg,
          confirmText: 'Buka File',
        ).then((confirmed) {
           if (confirmed == true) OpenFilex.open(path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(context, 'Gagal ekspor: $e');
      }
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'Laporan & Statistik',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: _exportExcel,
                        icon: const Icon(Icons.download_rounded, color: Colors.white),
                        tooltip: 'Export Excel',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Analytics Section
            if (!_loading && _allRecords.isNotEmpty) _buildAnalyticsSection(),

            // Filters & Date Range Selection
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Filter Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (v) {
                      _searchQuery = v;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama karyawan...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _periodChip('week', 'Minggu Ini'),
                        _periodChip('month', 'Bulan Ini'),
                        _periodChip('year', 'Tahun Ini'),
                        _periodChip('custom', 'Pilih Tanggal'),
                      ],
                    ),
                  ),
                  
                  if (_periodFilter == 'custom') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateInput('Mulai', true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDateInput('Selesai', false)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('ALL', 'Semua'),
                        _filterChip('PRESENT', 'Hadir'),
                        _filterChip('LATE', 'Terlambat'),
                        _filterChip('ABSENT', 'Alpha'),
                        _filterChip('IZIN', 'Izin'),
                        _filterChip('SAKIT', 'Sakit'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _filteredRecords.isEmpty
                      ? Center(child: Text('Data tidak ditemukan', style: TextStyle(color: Colors.grey.shade500)))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF2563EB),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                            itemCount: _filteredRecords.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final r = _filteredRecords[i] as Map<String, dynamic>;
                              return _buildAttendanceCard(r);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String status, String label) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF0F172A),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2563EB),
        onSelected: (v) {
          setState(() {
            _statusFilter = status;
            _applyFilters();
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        showCheckmark: false,
      ),
    );
  }

  Widget _periodChip(String p, String label) {
    final isSelected = _periodFilter == p;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF2563EB),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        backgroundColor: const Color(0xFF2563EB).withOpacity(0.05),
        selectedColor: const Color(0xFF2563EB),
        onSelected: (v) {
          setState(() => _periodFilter = p);
          _loadData();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildDateInput(String label, bool isStart) {
    final date = isStart ? _selectedDateRange?.start : _selectedDateRange?.end;
    final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '-';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickSingleDate(isStart),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(child: Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSingleDate(bool isStart) async {
    final initial = (isStart ? _selectedDateRange?.start : _selectedDateRange?.end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB), onPrimary: Colors.white, onSurface: Color(0xFF0F172A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedDateRange = DateTimeRange(start: picked, end: _selectedDateRange?.end ?? picked.add(const Duration(days: 1)));
        } else {
          _selectedDateRange = DateTimeRange(start: _selectedDateRange?.start ?? picked.subtract(const Duration(days: 1)), end: picked);
        }
      });
      _loadData();
    }
  }

  Widget _buildAnalyticsSection() {
    // Agreggate data for charts
    Map<String, Map<String, int>> dailyStats = {};
    int present = 0, late = 0, absent = 0, other = 0;

    for (var r in _filteredRecords) {
      final date = (r['date'] ?? '').toString();
      final status = (r['status'] ?? '').toString().toUpperCase();
      
      if (!dailyStats.containsKey(date)) {
        dailyStats[date] = {'PRESENT': 0, 'LATE': 0, 'ABSENT': 0, 'OTHER': 0};
      }

      if (status == 'PRESENT') { present++; dailyStats[date]!['PRESENT'] = (dailyStats[date]!['PRESENT'] ?? 0) + 1; }
      else if (status == 'LATE') { late++; dailyStats[date]!['LATE'] = (dailyStats[date]!['LATE'] ?? 0) + 1; }
      else if (status == 'ABSENT') { absent++; dailyStats[date]!['ABSENT'] = (dailyStats[date]!['ABSENT'] ?? 0) + 1; }
      else { other++; dailyStats[date]!['OTHER'] = (dailyStats[date]!['OTHER'] ?? 0) + 1; }
    }

    final sortedDates = dailyStats.keys.toList()..sort();
    // Only show last 7 days in chart if many
    final displayDates = sortedDates.length > 7 ? sortedDates.sublist(sortedDates.length - 7) : sortedDates;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Statistik Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isLineChart = false),
                    icon: Icon(Icons.bar_chart_rounded, color: !_isLineChart ? const Color(0xFF2563EB) : Colors.grey.shade300),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isLineChart = true),
                    icon: Icon(Icons.show_chart_rounded, color: _isLineChart ? const Color(0xFF2563EB) : Colors.grey.shade300),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _isLineChart 
              ? _buildLineChart(displayDates, dailyStats)
              : _buildBarChart(displayDates, dailyStats),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem(Colors.green, 'Hadir'),
              _legendItem(Colors.orange, 'Telat'),
              _legendItem(Colors.red, 'Alpha'),
              _legendItem(Colors.blue, 'Izin'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<String> dates, Map<String, Map<String, int>> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= dates.length) return const SizedBox();
                final d = dates[val.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(d.substring(8), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dates.length, (i) {
          final d = dates[i];
          final s = data[d]!;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: s['PRESENT']!.toDouble(), color: Colors.green, width: 6),
              BarChartRodData(toY: s['LATE']!.toDouble(), color: Colors.orange, width: 6),
              BarChartRodData(toY: s['ABSENT']!.toDouble(), color: Colors.red, width: 6),
              BarChartRodData(toY: s['OTHER']!.toDouble(), color: Colors.blue, width: 6),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(List<String> dates, Map<String, Map<String, int>> data) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= dates.length) return const SizedBox();
                final d = dates[val.toInt()];
                return Text(d.substring(8), style: TextStyle(color: Colors.grey.shade500, fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _lineData(dates, data, 'PRESENT', Colors.green),
          _lineData(dates, data, 'LATE', Colors.orange),
          _lineData(dates, data, 'ABSENT', Colors.red),
          _lineData(dates, data, 'OTHER', Colors.blue),
        ],
      ),
    );
  }

  LineChartBarData _lineData(List<String> dates, Map<String, Map<String, int>> data, String key, Color color) {
    return LineChartBarData(
      spots: List.generate(dates.length, (i) => FlSpot(i.toDouble(), data[dates[i]]![key]!.toDouble())),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> r) {
    final status = (r['status'] ?? r['type'] ?? '').toString().toUpperCase();
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case 'PRESENT': statusColor = Colors.green; statusLabel = 'Hadir'; break;
      case 'LATE': statusColor = Colors.orange; statusLabel = 'Terlambat'; break;
      case 'ABSENT': statusColor = Colors.red; statusLabel = 'Alpha'; break;
      case 'LEAVE': 
      case 'IZIN': statusColor = Colors.blue; statusLabel = 'Izin'; break;
      case 'SICK': 
      case 'SAKIT': statusColor = Colors.purple; statusLabel = 'Sakit'; break;
      default: statusColor = Colors.grey; statusLabel = status;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
            child: Text((r['user_name'] ?? 'K').substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['user_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                Text(r['date'] ?? '-', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              const SizedBox(height: 4),
              Text(
                r['is_leave'] == true
                    ? (r['title']?.toString() ?? 'Cuti/Izin')
                    : '${r['check_in_time']?.toString().substring(11, 16) ?? '--:--'} - ${r['check_out_time']?.toString().substring(11, 16) ?? '--:--'}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
