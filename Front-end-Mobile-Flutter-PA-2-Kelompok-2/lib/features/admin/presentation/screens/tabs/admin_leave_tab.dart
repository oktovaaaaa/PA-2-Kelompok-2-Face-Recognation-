// lib/features/admin/presentation/screens/tabs/admin_leave_tab.dart

import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';

class AdminLeaveTab extends StatefulWidget {
  const AdminLeaveTab({super.key});

  @override
  State<AdminLeaveTab> createState() => _AdminLeaveTabState();
}

class _AdminLeaveTabState extends State<AdminLeaveTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _leaves = [];
  bool _loading = false;
  String _selectedStatus = 'PENDING';

  final _statusLabels = {'PENDING': 'Menunggu', 'APPROVED': 'Disetujui', 'REJECTED': 'Ditolak'};
  final _statusColors = {
    'PENDING': Colors.orange,
    'APPROVED': Colors.green,
    'REJECTED': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      final statuses = ['PENDING', 'APPROVED', 'REJECTED'];
      _selectedStatus = statuses[_tabController.index];
      _loadLeaves();
    });
    _loadLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaves() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/admin/leaves?status=$_selectedStatus');
      if (res.success && mounted) {
        setState(() => _leaves = res.data ?? []);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processLeave(String id, String action) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(action == 'approve' ? 'Setujui Izin' : 'Tolak Izin',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(action == 'approve'
                ? 'Apakah Anda yakin ingin menyetujui izin ini?'
                : 'Apakah Anda yakin ingin menolak izin ini?'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action == 'approve' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final res = await ApiClient.put('/api/admin/leaves/$id/$action', {'note': noteCtrl.text});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success ? (action == 'approve' ? 'Izin disetujui' : 'Izin ditolak') : (res.message ?? 'Gagal')),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ),
      );
      if (res.success) _loadLeaves();
    } catch (_) {}
  }

  void _showDetail(Map<String, dynamic> leave) {
    final status = leave['status'] ?? '';
    final color = _statusColors[status] ?? Colors.grey;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(leave['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                Chip(
                  label: Text(_statusLabels[status] ?? status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Karyawan: ${leave['user_name'] ?? '-'}', style: TextStyle(color: Colors.grey.shade700)),
            Text('Email: ${leave['user_email'] ?? '-'}', style: TextStyle(color: Colors.grey.shade700)),
            Text('Tipe: ${leave['type'] ?? '-'}', style: TextStyle(color: Colors.grey.shade700)),
            const Divider(height: 24),
            Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            const SizedBox(height: 4),
            Text(leave['description'] ?? '-'),
            if (leave['admin_note'] != null && (leave['admin_note'] as String).isNotEmpty) ...[
              const Divider(height: 24),
              Text('Catatan Admin:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              const SizedBox(height: 4),
              Text(leave['admin_note']),
            ],
            if (status == 'PENDING') ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () { Navigator.pop(ctx); _processLeave(leave['id'], 'approve'); },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { Navigator.pop(ctx); _processLeave(leave['id'], 'reject'); },
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF4D64F5),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: const [Tab(text: 'Menunggu'), Tab(text: 'Disetujui'), Tab(text: 'Ditolak')],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _leaves.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Tidak ada izin', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeaves,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leaves.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final l = _leaves[i] as Map<String, dynamic>;
                          final status = l['status'] ?? '';
                          final color = _statusColors[status] ?? Colors.grey;
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: color.withAlpha(30),
                                child: Icon(
                                  l['type'] == 'SAKIT' ? Icons.sick_rounded : Icons.event_busy_rounded,
                                  color: color,
                                ),
                              ),
                              title: Text(l['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${l['user_name'] ?? '-'} • ${l['type'] ?? '-'}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              trailing: Chip(
                                label: Text(_statusLabels[status] ?? status,
                                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                                backgroundColor: color,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onTap: () => _showDetail(l),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
