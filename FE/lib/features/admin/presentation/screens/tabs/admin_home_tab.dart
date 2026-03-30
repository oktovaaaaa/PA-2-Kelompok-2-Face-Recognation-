// lib/features/admin/presentation/screens/tabs/admin_home_tab.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/session_storage.dart';
import '../../../../../core/utils/error_mapper.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../../auth/presentation/screens/pending_employees_screen.dart';
import '../attendance_report_screen.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final _repo = AuthRepository();
  bool _loadingInvite = false;
  String _generatedToken = '';
  final GlobalKey _qrKey = GlobalKey();
  String? _userName;
  Map<String, dynamic> _summary = {'present': 0, 'absent': 0, 'late': 0, 'leave': 0, 'total': 0};
  bool _loadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      // Assuming this endpoint exists or we aggregate data
      final res = await ApiClient.get('/api/admin/dashboard/summary');
      if (res.success && mounted) {
        setState(() => _summary = res.data ?? _summary);
      }
    } catch (_) {
      // Fallback or silence
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadUserName() async {
    final name = await SessionStorage.getUserName();
    if (mounted) setState(() => _userName = name);
  }

  Future<void> _generateInvite() async {
    setState(() => _loadingInvite = true);
    try {
      final companyId = await SessionStorage.getCompanyId() ?? '';
      final data = await _repo.generateInvite(companyId);
      _generatedToken = (data['token'] ?? '').toString();
      setState(() {});
    } catch (e) {
      final msg = ErrorMapper.map(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loadingInvite = false);
    }
  }

  Future<void> _copyToken() async {
    await Clipboard.setData(ClipboardData(text: _generatedToken));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token disalin ke clipboard!')),
    );
  }

  Future<void> _saveQrCode() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final result = await ImageGallerySaverPlus.saveImage(
        byteData.buffer.asUint8List(),
        quality: 100,
        name: "invite_qr_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['isSuccess'] == true ? 'QR disimpan ke galeri!' : 'Gagal menyimpan QR.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menyimpan gambar.')),
      );
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
            padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 28),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${_userName ?? 'Admin'} 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola perusahaan dengan mudah',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      (_userName ?? 'A').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_graph_rounded, color: Color(0xFF2563EB), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Live Statistics',
                                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateTime.now().toString().substring(0, 10),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ringkasan Kehadiran',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status kehadiran karyawan hari ini',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      if (_summary['total'] == 0 && !_loadingSummary)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text('Belum ada data kehadiran hari ini', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                        )
                      else if (_loadingSummary)
                        const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: Color(0xFF2563EB))))
                      else
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 25,
                                  sections: [
                                    if (_summary['present'] > 0) PieChartSectionData(value: (_summary['present'] as num).toDouble(), color: Colors.green, radius: 20, showTitle: false),
                                    if (_summary['late'] > 0) PieChartSectionData(value: (_summary['late'] as num).toDouble(), color: Colors.orange, radius: 20, showTitle: false),
                                    if (_summary['absent'] > 0) PieChartSectionData(value: (_summary['absent'] as num).toDouble(), color: Colors.red, radius: 20, showTitle: false),
                                    if (_summary['leave'] > 0) PieChartSectionData(value: (_summary['leave'] as num).toDouble(), color: Colors.blue, radius: 20, showTitle: false),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _summaryItem(Colors.green, 'Hadir', _summary['present']),
                                  const SizedBox(height: 8),
                                  _summaryItem(Colors.orange, 'Terlambat', _summary['late']),
                                  const SizedBox(height: 8),
                                  _summaryItem(Colors.red, 'Alpha', _summary['absent']),
                                  const SizedBox(height: 8),
                                  _summaryItem(Colors.blue, 'Izin/Sakit', (_summary['leave'] ?? 0) + (_summary['sick'] ?? 0)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Manajemen & Laporan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Laporan Kehadiran',
                  subtitle: 'Lihat seluruh riwayat & ekspor Excel',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                  ),
                ),
                const SizedBox(height: 16),

                _buildMenuCard(
                  context,
                  icon: Icons.person_add_rounded,
                  color: const Color(0xFF2563EB),
                  title: 'Karyawan Pending',
                  subtitle: 'Approve atau reject pendaftaran baru',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PendingEmployeesScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.qr_code_2_rounded,
                  color: const Color(0xFF0F172A),
                  title: 'Generate Undangan',
                  subtitle: 'Buat Token & QR Code rekrutmen',
                  onTap: _loadingInvite ? null : _generateInvite,
                  trailing: _loadingInvite
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                      : null,
                ),
                
                if (_generatedToken.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('QR Undangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          RepaintBoundary(
                            key: _qrKey,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100, width: 2),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: QrImageView(data: _generatedToken, version: QrVersions.auto, size: 200.0),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.vpn_key_rounded, color: Color(0xFF64748B), size: 18),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_generatedToken, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)))),
                                GestureDetector(
                                   onTap: _copyToken,
                                   child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.copy_rounded, color: Color(0xFF2563EB), size: 16),
                                   ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveQrCode,
                              icon: const Icon(Icons.file_download_rounded),
                              label: const Text('Simpan Ke Galeri', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _summaryItem(Color color, String label, dynamic count) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const Spacer(),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
