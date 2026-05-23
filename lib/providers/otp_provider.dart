import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Simple OTP provider that generates and validates short-lived OTP codes.
class OtpProvider with ChangeNotifier {
  String? _currentOtp;
  DateTime? _expiresAt;
  Timer? _expiryTimer;

  Duration get ttl => const Duration(minutes: 5);

  /// Generate a numeric OTP (6 digits by default)
  String generateOtp({int length = 6}) {
    final rnd = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(rnd.nextInt(10));
    }
    _currentOtp = buffer.toString();
    _expiresAt = DateTime.now().add(ttl);

    _expiryTimer?.cancel();
    _expiryTimer = Timer(ttl, () {
      _currentOtp = null;
      _expiresAt = null;
      notifyListeners();
    });

    if (kDebugMode)
      debugPrint('OTP generated: $_currentOtp (expires at $_expiresAt)');
    notifyListeners();
    return _currentOtp!;
  }

  /// Validate provided OTP (returns true if matches and not expired)
  bool validateOtp(String otp) {
    if (_currentOtp == null || _expiresAt == null) return false;
    if (DateTime.now().isAfter(_expiresAt!)) return false;
    return _currentOtp == otp;
  }

  /// Clear OTP
  void clearOtp() {
    _currentOtp = null;
    _expiresAt = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
