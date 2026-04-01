import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../common/widgets/app_dialog.dart';

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
    final confirmed = await AppDialog.showConfirm(
      context,
      title: action == 'approve' ? 'Setujui Izin' : 'Tolak Izin',
      message: action == 'approve'
          ? 'Apakah Anda yakin ingin menyetujui izin ini?'
          : 'Apakah Anda yakin ingin menolak izin ini?',
      confirmText: action == 'approve' ? 'Setujui' : 'Tolak',
      confirmColor: action == 'approve' ? Colors.green : Colors.red,
    );

    if (confirmed != true) return;
    try {
      final res = await ApiClient.put('/api/admin/leaves/$id/$action', {'note': noteCtrl.text});
      if (!mounted) return;
      if (res.success) {
        AppDialog.showSuccess(context, action == 'approve' ? 'Izin disetujui' : 'Izin ditolak');
        _loadLeaves();
      } else {
        AppDialog.showError(context, res.message ?? 'Gagal memproses izin');
      }
    } catch (_) {}
  }

  void _showDetail(Map<String, dynamic> leave) {
    final status = leave['status'] ?? '';
    final color = _statusColors[status] ?? Colors.grey;
    final isPending = status == 'PENDING';
    final typeIcon = leave['type'] == 'SAKIT' ? Icons.medical_services_rounded : Icons.assignment_rounded;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // 1. Header & Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Icon(typeIcon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(leave['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                              child: Text(_statusLabels[status] ?? status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 2. Data Pengaju Card
                  _buildSectionTitle('Informasi Pengaju'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.person_outline_rounded, 'Karyawan', leave['user_name'] ?? '-'),
                    _buildInfoRow(Icons.alternate_email_rounded, 'Email', leave['user_email'] ?? '-'),
                  ]),
                  const SizedBox(height: 24),

                  // 3. Detail Pengajuan Card
                  _buildSectionTitle('Detail Pengajuan'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.category_outlined, 'Tipe Izin', leave['type'] ?? '-'),
                    _buildInfoRow(Icons.description_outlined, 'Deskripsi', leave['description'] ?? '-', isMultiline: true),
                  ]),
                  const SizedBox(height: 24),

                  // 4. Catatan Admin
                  if (leave['admin_note'] != null && (leave['admin_note'] as String).isNotEmpty) ...[
                    _buildSectionTitle('Tanggapan Admin'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF475569)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              leave['admin_note'],
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF475569), height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // 5. Action Buttons (If Pending)
                  if (isPending)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () { Navigator.pop(ctx); _processLeave(leave['id'], 'approve'); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () { Navigator.pop(ctx); _processLeave(leave['id'], 'reject'); },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade600, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Tolak', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  'Manajemen Izin',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tinjau dan proses pengajuan izin karyawan',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 24),
                // Premium TabBar
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
                  indicatorColor: Colors.white,
                  dividerColor: Colors.transparent,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Menunggu'),
                    Tab(text: 'Disetujui'),
                    Tab(text: 'Ditolak'),
                  ],
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
                              child: Icon(Icons.assignment_late_rounded, size: 64, color: Colors.grey.shade300),
                            ),
                            const SizedBox(height: 16),
                            Text('Tidak ada data izin', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeaves,
                        color: const Color(0xFF2563EB),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          itemCount: _leaves.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final l = _leaves[i] as Map<String, dynamic>;
                            final status = l['status'] ?? '';
                            final color = _statusColors[status] ?? Colors.grey;
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
                                  onTap: () => _showDetail(l),
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
                                                '${l['user_name'] ?? '-'} • ${l['type'] ?? '-'}',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 24),
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
