import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyPassword = 'ge_pwd_';
  static const _keyOtp      = 'ge_otp_';
  static const _keyOtpExp   = 'ge_otp_exp_';

  static bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static final Map<String, String> _fallback = {};

  static Future<void> savePassword(String email, String hashedPwd) async {
    final key = '$_keyPassword${email.toLowerCase()}';
    if (_isDesktop) { _fallback[key] = hashedPwd; return; }
    await _storage.write(key: key, value: hashedPwd);
  }

  static Future<String?> getPassword(String email) async {
    final key = '$_keyPassword${email.toLowerCase()}';
    if (_isDesktop) return _fallback[key];
    return await _storage.read(key: key);
  }

  static Future<void> deletePassword(String email) async {
    final key = '$_keyPassword${email.toLowerCase()}';
    if (_isDesktop) { _fallback.remove(key); return; }
    await _storage.delete(key: key);
  }

  static Future<void> saveOtp(String email, String otp, DateTime expiry) async {
    final keyOtp = '$_keyOtp${email.toLowerCase()}';
    final keyExp = '$_keyOtpExp${email.toLowerCase()}';
    if (_isDesktop) {
      _fallback[keyOtp] = otp;
      _fallback[keyExp] = expiry.toIso8601String();
      return;
    }
    await _storage.write(key: keyOtp, value: otp);
    await _storage.write(key: keyExp, value: expiry.toIso8601String());
  }

  static Future<bool> verifyOtp(String email, String inputOtp) async {
    final keyOtp = '$_keyOtp${email.toLowerCase()}';
    final keyExp = '$_keyOtpExp${email.toLowerCase()}';
    String? storedOtp, storedExp;
    if (_isDesktop) {
      storedOtp = _fallback[keyOtp];
      storedExp = _fallback[keyExp];
    } else {
      storedOtp = await _storage.read(key: keyOtp);
      storedExp = await _storage.read(key: keyExp);
    }
    if (storedOtp == null || storedExp == null) return false;
    final expiry = DateTime.tryParse(storedExp);
    if (expiry == null || DateTime.now().isAfter(expiry)) return false;
    return storedOtp == inputOtp.trim();
  }

  static Future<void> clearOtp(String email) async {
    final keyOtp = '$_keyOtp${email.toLowerCase()}';
    final keyExp = '$_keyOtpExp${email.toLowerCase()}';
    if (_isDesktop) {
      _fallback.remove(keyOtp);
      _fallback.remove(keyExp);
      return;
    }
    await _storage.delete(key: keyOtp);
    await _storage.delete(key: keyExp);
  }
}
