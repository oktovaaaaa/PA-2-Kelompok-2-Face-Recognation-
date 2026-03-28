// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/session_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SessionProvider>(
          create: (context) => SessionProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) {
            return previous ?? SessionProvider(authProvider: auth);
          },
        ),
      ],
      child: const EmployeeSystemApp(),
    ),
  );
}