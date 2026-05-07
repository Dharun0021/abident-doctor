import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorAuthStorage {
  DoctorAuthStorage._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _isLoggedInKey = 'doctor_is_logged_in';
  static const String _doctorIdKey = 'doctor_id';
  static const String _doctorNameKey = 'doctor_name';
  static const String _doctorEmailKey = 'doctor_email';
  static const String _doctorSpecializationKey = 'doctor_specialization';
  static const String _tokenKey = 'doctor_auth_token';

  static Future<void> saveSession({
    required String token,
    required String doctorId,
    required String doctorName,
    required String doctorEmail,
    required String specialization,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_doctorIdKey, doctorId);
    await prefs.setString(_doctorNameKey, doctorName);
    await prefs.setString(_doctorEmailKey, doctorEmail);
    await prefs.setString(_doctorSpecializationKey, specialization);
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  static Future<String?> getDoctorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorNameKey);
  }

  static Future<String?> getDoctorEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorEmailKey);
  }

  static Future<String?> getSpecialization() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorSpecializationKey);
  }

  static Future<void> updateDoctorData({
    String? name,
    String? email,
    String? specialization,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_doctorNameKey, name);
    if (email != null) await prefs.setString(_doctorEmailKey, email);
    if (specialization != null) {
      await prefs.setString(_doctorSpecializationKey, specialization);
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_doctorIdKey);
    await prefs.remove(_doctorNameKey);
    await prefs.remove(_doctorEmailKey);
    await prefs.remove(_doctorSpecializationKey);
    await _secureStorage.delete(key: _tokenKey);
  }
}
