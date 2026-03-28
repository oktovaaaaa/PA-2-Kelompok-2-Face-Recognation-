import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/storage/session_storage.dart';
import 'admin_dashboard_screen.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import 'login_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _loading = true;
  Widget _target = const SizedBox();

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await SessionStorage.getToken();
    final role = await SessionStorage.getRole();

    if (token != null && token.isNotEmpty) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).setAuthenticated(true);
      }
      if (role == 'ADMIN') {
        _target = const AdminDashboardScreen();
      } else {
        _target = const LoginScreen(pinOnlyMode: true);
      }
    } else {
      _target = const LandingScreen();
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _target;
  }
}