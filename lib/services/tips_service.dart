import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which one-time in-app tips have been shown to the user.
/// Each tip is identified by a unique [tipId] string.
class TipsService {
  static const _prefix = 'tip_shown_';

  /// Returns true if the tip with [tipId] has NOT been shown yet.
  static Future<bool> shouldShow(String tipId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_prefix$tipId') ?? false);
  }

  /// Marks the tip with [tipId] as shown so it won't appear again.
  static Future<void> markShown(String tipId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$tipId', true);
  }
}
