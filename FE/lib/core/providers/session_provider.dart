// lib/core/providers/session_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_provider.dart';

class SessionProvider extends ChangeNotifier {
  Timer? _inactivityTimer;
  final AuthProvider authProvider;
  DateTime? _lastActiveTime;

  SessionProvider({required this.authProvider}) {
    // Listen to AuthProvider changes – when user logs in, start the timer automatically
    authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (authProvider.isAuthenticated && !authProvider.isSessionLocked) {
      startTimer();
    } else {
      _cancelTimer();
    }
  }

  void startTimer() {
    _cancelTimer();
    if (!authProvider.isAuthenticated) return; 

    // Update last activity time but Don't start an inactivity timer for foreground use
    // to strictly follow user request (lock only when backgrounded).
    _lastActiveTime = DateTime.now();
  }

  void resetTimer() {
    if (authProvider.isAuthenticated && !authProvider.isSessionLocked) {
      startTimer();
    }
  }

  void _cancelTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    if (!authProvider.isAuthenticated) return; // Ignore if not logged in

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lastActiveTime = DateTime.now();
      _cancelTimer(); // Stop the timer when backgrounded
    } else if (state == AppLifecycleState.resumed) {
      if (_lastActiveTime != null) {
        final diff = DateTime.now().difference(_lastActiveTime!);
        if (diff.inMinutes >= 15) {
          authProvider.lockSession();
        } else {
          startTimer(); // Resume the timer
        }
      }
    }
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    _cancelTimer();
    super.dispose();
  }
}
