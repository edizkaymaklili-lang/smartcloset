import '../../../../core/enums/body_type.dart';
import '../../../../core/enums/color_season.dart';
import '../../../../core/enums/height_range.dart';
import '../../../../core/enums/style_preference.dart';
import '../../../../core/enums/user_hobby.dart';
import '../../../../core/enums/work_type.dart';

class UserProfile {
  final String displayName;
  final int age;
  final StylePreference stylePreference;
  final String workStatus; // eski alan, uyumluluk için korunuyor
  final String city;
  final bool notificationEnabled;

  // Faz 1: Kişiselleştirme alanları
  final BodyType? bodyType;
  final HeightRange? heightRange;
  final WorkType? workType;
  final List<UserHobby> hobbies;
  final ColorSeason? colorSeason;

  const UserProfile({
    required this.displayName,
    required this.age,
    required this.stylePreference,
    required this.workStatus,
    required this.city,
    this.notificationEnabled = true,
    this.bodyType,
    this.heightRange,
    this.workType,
    this.hobbies = const [],
    this.colorSeason,
  });

  UserProfile copyWith({
    String? displayName,
    int? age,
    StylePreference? stylePreference,
    String? workStatus,
    String? city,
    bool? notificationEnabled,
    BodyType? bodyType,
    HeightRange? heightRange,
    WorkType? workType,
    List<UserHobby>? hobbies,
    ColorSeason? colorSeason,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      stylePreference: stylePreference ?? this.stylePreference,
      workStatus: workStatus ?? this.workStatus,
      city: city ?? this.city,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      bodyType: bodyType ?? this.bodyType,
      heightRange: heightRange ?? this.heightRange,
      workType: workType ?? this.workType,
      hobbies: hobbies ?? this.hobbies,
      colorSeason: colorSeason ?? this.colorSeason,
    );
  }

  /// Profil tamamlanma yüzdesi (kişiselleştirme alanları)
  double get profileCompleteness {
    int filled = 0;
    int total = 5;
    if (bodyType != null) filled++;
    if (heightRange != null) filled++;
    if (workType != null) filled++;
    if (hobbies.isNotEmpty) filled++;
    if (colorSeason != null) filled++;
    return filled / total;
  }

  /// Kişiselleştirme profili tamamlanmış mı?
  bool get isPersonalized => profileCompleteness >= 0.6;
}
