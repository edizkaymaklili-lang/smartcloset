import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings
class SettingsService {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyLocation = 'location_enabled';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyBackgroundRemoval = 'background_removal_enabled';
  static const String _keyRemoveBgApiKey = 'remove_bg_api_key';

  /// Get notifications enabled setting
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  /// Set notifications enabled setting
  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  /// Get location enabled setting
  Future<bool> getLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLocation) ?? true;
  }

  /// Set location enabled setting
  Future<void> setLocationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocation, value);
  }

  /// Get dark mode setting
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  /// Set dark mode setting
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  /// Get background removal enabled setting
  Future<bool> getBackgroundRemovalEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBackgroundRemoval) ?? false;
  }

  /// Set background removal enabled setting
  Future<void> setBackgroundRemovalEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBackgroundRemoval, value);
  }

  /// Get remove.bg API key
  Future<String> getRemoveBgApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRemoveBgApiKey) ?? '';
  }

  /// Set remove.bg API key
  Future<void> setRemoveBgApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRemoveBgApiKey, value);
  }
}
