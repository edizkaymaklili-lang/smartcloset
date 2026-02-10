import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/enums/body_type.dart';
import '../../../../core/enums/color_season.dart';
import '../../../../core/enums/height_range.dart';
import '../../../../core/enums/style_preference.dart';
import '../../../../core/enums/user_hobby.dart';
import '../../../../core/enums/work_type.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../services/notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with override in main()');
});

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends Notifier<UserProfile> {
  static const _keyStyle = 'style_preference';
  static const _keyName = 'display_name';
  static const _keyCity = 'city';
  static const _keyOnboarded = 'onboarding_done';
  static const _keyBodyType = 'body_type';
  static const _keyHeightRange = 'height_range';
  static const _keyWorkType = 'work_type';
  static const _keyHobbies = 'hobbies';
  static const _keyColorSeason = 'color_season';

  @override
  UserProfile build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return UserProfile(
      displayName: prefs.getString(_keyName) ?? 'Style Enthusiast',
      age: 25,
      stylePreference: StylePreference.values.firstWhere(
        (s) => s.name == (prefs.getString(_keyStyle) ?? 'classic'),
        orElse: () => StylePreference.classic,
      ),
      workStatus: 'working',
      city: prefs.getString(_keyCity) ?? 'Istanbul',
      notificationEnabled: prefs.getBool('notification_enabled') ?? true,
      bodyType: _loadEnum(prefs, _keyBodyType, BodyType.values),
      heightRange: _loadEnum(prefs, _keyHeightRange, HeightRange.values),
      workType: _loadEnum(prefs, _keyWorkType, WorkType.values),
      hobbies: _loadHobbies(prefs),
      colorSeason: _loadEnum(prefs, _keyColorSeason, ColorSeason.values),
    );
  }

  /// Generic enum loader from SharedPreferences
  T? _loadEnum<T extends Enum>(SharedPreferences prefs, String key, List<T> values) {
    final saved = prefs.getString(key);
    if (saved == null) return null;
    try {
      return values.firstWhere((v) => v.name == saved);
    } catch (_) {
      return null;
    }
  }

  List<UserHobby> _loadHobbies(SharedPreferences prefs) {
    final saved = prefs.getStringList(_keyHobbies);
    if (saved == null) return [];
    return saved
        .map((name) {
          try {
            return UserHobby.values.firstWhere((h) => h.name == name);
          } catch (_) {
            return null;
          }
        })
        .whereType<UserHobby>()
        .toList();
  }

  void updateStylePreference(StylePreference style) {
    ref.read(sharedPreferencesProvider).setString(_keyStyle, style.name);
    state = state.copyWith(stylePreference: style);
  }

  void updateName(String name) {
    ref.read(sharedPreferencesProvider).setString(_keyName, name);
    state = state.copyWith(displayName: name);
  }

  /// Alias for updateName - used by settings screen
  void updateDisplayName(String name) => updateName(name);

  void updateCity(String city) {
    ref.read(sharedPreferencesProvider).setString(_keyCity, city);
    state = state.copyWith(city: city);
  }

  void updateBodyType(BodyType bodyType) {
    ref.read(sharedPreferencesProvider).setString(_keyBodyType, bodyType.name);
    state = state.copyWith(bodyType: bodyType);
  }

  void updateHeightRange(HeightRange heightRange) {
    ref.read(sharedPreferencesProvider).setString(_keyHeightRange, heightRange.name);
    state = state.copyWith(heightRange: heightRange);
  }

  void updateWorkType(WorkType workType) {
    ref.read(sharedPreferencesProvider).setString(_keyWorkType, workType.name);
    state = state.copyWith(workType: workType);
  }

  void updateHobbies(List<UserHobby> hobbies) {
    ref.read(sharedPreferencesProvider).setStringList(
      _keyHobbies,
      hobbies.map((h) => h.name).toList(),
    );
    state = state.copyWith(hobbies: hobbies);
  }

  void updateColorSeason(ColorSeason colorSeason) {
    ref.read(sharedPreferencesProvider).setString(_keyColorSeason, colorSeason.name);
    state = state.copyWith(colorSeason: colorSeason);
  }

  Future<void> toggleNotifications(bool enabled) async {
    ref.read(sharedPreferencesProvider).setBool('notification_enabled', enabled);
    state = state.copyWith(notificationEnabled: enabled);

    final notificationService = NotificationService();

    if (enabled) {
      // Request permissions first
      final hasPermission = await notificationService.requestPermissions();
      if (hasPermission) {
        // Schedule daily morning notifications
        await notificationService.scheduleDailyMorningNotification();
      }
    } else {
      // Cancel all notifications
      await notificationService.cancelAllNotifications();
    }
  }

  void completeOnboarding() {
    ref.read(sharedPreferencesProvider).setBool(_keyOnboarded, true);
  }

  bool get isOnboarded =>
      ref.read(sharedPreferencesProvider).getBool(_keyOnboarded) ?? false;
}
