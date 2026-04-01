import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings
class SettingsService {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyLocation = 'location_enabled';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyBackgroundRemoval = 'background_removal_enabled';
  static const String _keyRemoveBgApiKey = 'remove_bg_api_key';
  static const String _keyGeminiApiKey = 'gemini_api_key';

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

  // Embedded at build time via --dart-define=REMOVE_BG_KEY=...
  // Not visible in source code or git history.
  static const _builtInKey = String.fromEnvironment('REMOVE_BG_KEY', defaultValue: '');

  /// Get remove.bg API key (user-saved key takes priority, then built-in key)
  Future<String> getRemoveBgApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyRemoveBgApiKey) ?? '';
    return saved.isNotEmpty ? saved : _builtInKey;
  }

  /// Set remove.bg API key
  Future<void> setRemoveBgApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRemoveBgApiKey, value);
  }

  /// Get Gemini API key
  Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey) ?? 'AIzaSyA8_LJ2Jnv5A7MvVc9Qi3zEUEiX2ry9uNI';
  }

  /// Set Gemini API key
  Future<void> setGeminiApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, value);
  }
}
