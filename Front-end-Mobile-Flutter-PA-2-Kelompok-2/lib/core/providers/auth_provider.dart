// lib/core/providers/auth_provider.dart

import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isSessionLocked = false;
  Map<String, dynamic>? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isSessionLocked => _isSessionLocked;
  Map<String, dynamic>? get currentUser => _currentUser;

  void setAuthenticated(bool val) {
    _isAuthenticated = val;
    notifyListeners();
  }

  void login(Map<String, dynamic> user) {
    _isAuthenticated = true;
    _isSessionLocked = false;
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _isSessionLocked = false;
    _currentUser = null;
    notifyListeners();
  }

  void lockSession() {
    _isSessionLocked = true;
    notifyListeners();
  }

  void unlockSession() {
    if (_isSessionLocked) {
      _isSessionLocked = false;
      notifyListeners();
    }
  }
}
