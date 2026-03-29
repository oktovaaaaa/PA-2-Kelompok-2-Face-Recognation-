// lib/features/employee/presentation/screens/employee_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import 'tabs/employee_attendance_tab.dart';
import 'tabs/employee_history_tab.dart';
import 'tabs/employee_leave_tab.dart';
import 'tabs/employee_profile_tab.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    EmployeeAttendanceTab(),
    EmployeeHistoryTab(),
    EmployeeLeaveTab(),
    EmployeeProfileTab(),
  ];

  Future<void> _logout() async {
    final act = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
    final labels = ['Kehadiran', 'Riwayat', 'Izin', 'Profil'];
    final icons = [
      Icons.fingerprint_rounded,
      Icons.history_rounded,
      Icons.assignment_late_rounded,
      Icons.person_rounded,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          labels[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded), tooltip: 'Keluar'),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2E7D32).withAlpha(30),
        destinations: List.generate(
          labels.length,
          (i) => NavigationDestination(
            icon: Icon(icons[i]),
            selectedIcon: Icon(icons[i], color: const Color(0xFF2E7D32)),
            label: labels[i],
          ),
        ),
      ),
    );
  }
}
