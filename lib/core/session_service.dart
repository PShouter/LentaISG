import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyTkNumber = 'portal_tk_number';
  static const _keyIsAdmin = 'portal_is_admin';

  static Future<void> saveTkSession(String tkNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTkNumber, tkNumber);
    await prefs.setBool(_keyIsAdmin, false);
  }

  static Future<void> saveAdminSession(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsAdmin, isAdmin);
    await prefs.remove(_keyTkNumber);
  }

  static Future<String?> getSavedTk() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTkNumber);
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin) ?? false;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTkNumber);
    await prefs.remove(_keyIsAdmin);
  }
}
