import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _loginTime;
  Timer? _sessionTimer;

  static const Duration _sessionTimeout = Duration(minutes: 30);

  final _authService = AuthService.instance;
  final _storage = StorageService.instance;

  User? get user => _user;
  String? get userId => _user?.id.toString();
  String? get userRole => _user?.role;
  String? get userName => _user?.name;
  String? get userEmail => _user?.email;
  String? get userPhone => _user?.phone;
  String? get userStatus => _user?.status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  DateTime? get loginTime => _loginTime;

  Future<void> checkAuthStatus() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final userData = await _authService.getCurrentUser();
        _user = User.fromJson(userData['user'] ?? userData);
        _loginTime = DateTime.now();
        _startSessionTimer();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Auth check error: $e');
      await _storage.clearAuthData();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.trim().isEmpty) {
        _errorMessage = 'Email cannot be empty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Password cannot be empty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint('🔐 Attempting login...');
      final data = await _authService.login(
        email: email.trim(),
        password: password,
      );

      debugPrint('✅ Login response received');
      debugPrint('   User data: ${data['user']}');
      
      _user = User.fromJson(data['user'] ?? data);
      debugPrint('✅ User object created: ${_user!.firstName} ${_user!.lastName}');
      
      _loginTime = DateTime.now();
      _errorMessage = null;
      _isLoading = false;
      _startSessionTimer();

      notifyListeners();

      debugPrint('✅ Login successful: ${_user!.name} (${_user!.role})');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Login error: $e');
      debugPrint('   Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        role: role,
      );

      _user = User.fromJson(data['user'] ?? data);
      _loginTime = DateTime.now();
      _errorMessage = null;
      _isLoading = false;
      _startSessionTimer();

      notifyListeners();

      debugPrint('✅ Registration successful: ${_user!.name}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _stopSessionTimer();
      _user = null;
      _errorMessage = null;
      _loginTime = null;
      _isLoading = false;

      notifyListeners();
      debugPrint('👋 User logged out');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    if (!isAuthenticated) {
      _errorMessage = 'Not authenticated';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );

      _user = User.fromJson(data['user'] ?? data);
      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Profile updated successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Profile update error: $e');
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!isAuthenticated) {
      _errorMessage = 'Not authenticated';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Password changed successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Password change error: $e');
      return false;
    }
  }

  void _startSessionTimer() {
    _stopSessionTimer();
    _sessionTimer = Timer(_sessionTimeout, () {
      debugPrint('⏰ Session timeout - Auto logout');
      logout();
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void refreshSession() {
    if (isAuthenticated) {
      _startSessionTimer();
      debugPrint('🔄 Session refreshed');
    }
  }

  Duration? getRemainingSessionTime() {
    if (_loginTime == null) return null;
    final elapsed = DateTime.now().difference(_loginTime!);
    final remaining = _sessionTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool hasRole(String role) {
    return _user?.role.toLowerCase() == role.toLowerCase();
  }

  bool hasAnyRole(List<String> roles) {
    if (_user == null) return false;
    return roles.any((role) => role.toLowerCase() == _user!.role.toLowerCase());
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String getUserInitials() {
    if (_user == null) return '?';
    return _user!.initials;
  }

  String getUserFirstName() {
    if (_user == null) return 'User';
    return _user!.firstName;
  }

  Future<bool> validateSession() async {
    if (!isAuthenticated) return false;

    try {
      await checkAuthStatus();
      return isAuthenticated;
    } catch (e) {
      debugPrint('❌ Session validation error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}
