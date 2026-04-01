// lib/features/admin/presentation/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../../common/widgets/premium_bottom_nav.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/admin_leave_tab.dart';
import 'tabs/admin_position_tab.dart';
import 'tabs/admin_employee_tab.dart';
import 'tabs/admin_profile_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      AdminHomeTab(onNavigate: (i) => setState(() => _currentIndex = i)),
      const AdminLeaveTab(),
      const AdminPositionTab(),
      const AdminEmployeeTab(),
      const AdminProfileTab(),
    ];
  }

  Future<void> _logout() async {
    final act = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (act != true) return;
    await SessionStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Beranda', 'Perizinan', 'Jabatan', 'Karyawan', 'Profil'];
    final icons = [
      Icons.home_rounded,
      Icons.assignment_rounded,
      Icons.work_rounded,
      Icons.people_rounded,
      Icons.person_rounded,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Hide standard appBar, custom header will be in each tab
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      extendBody: false,
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavItem(icon: Icons.home_rounded, label: 'Beranda'),
          BottomNavItem(icon: Icons.assignment_rounded, label: 'Perizinan'),
          BottomNavItem(icon: Icons.work_rounded, label: 'Jabatan'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Karyawan'),
          BottomNavItem(icon: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }
}