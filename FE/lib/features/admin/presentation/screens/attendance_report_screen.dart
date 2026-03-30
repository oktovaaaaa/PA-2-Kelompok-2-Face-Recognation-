import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/excel_export_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:open_filex/open_filex.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Fetch both attendance history and approved leave requests in parallel
      final results = await Future.wait([
        ApiClient.get('/api/admin/attendance/history'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk diekspor')));
      return;
    }
    try {
      final path = await ExcelExportService.exportAttendance(_filteredRecords, 'Laporan_Kehadiran_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        String msg = 'Laporan berhasil dibuat';
        if (path.contains('Download')) {
          msg = 'Tersimpan di folder Download';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'Buka', textColor: Colors.white, onPressed: () => OpenFilex.open(path)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ekspor: $e'), backgroundColor: Colors.red));
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
                          'Laporan Kehadiran',
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

            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) {
                      _searchQuery = v;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama karyawan...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 12),
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
