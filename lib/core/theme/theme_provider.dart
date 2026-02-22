import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/settings_service.dart';

/// Provides the current [ThemeMode] and allows toggling dark/light mode.
final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  final _settings = SettingsService();

  @override
  Future<ThemeMode> build() async {
    final isDark = await _settings.getDarkMode();
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final current = state.asData?.value ?? ThemeMode.light;
    final isDark = current == ThemeMode.light;
    await _settings.setDarkMode(isDark);
    state = AsyncValue.data(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDark => state.asData?.value == ThemeMode.dark;
}
