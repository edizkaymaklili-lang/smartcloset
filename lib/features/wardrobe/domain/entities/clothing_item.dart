import '../../../../core/enums/clothing_category.dart';

class ClothingItem {
  final String id;
  final String name;
  final ClothingCategory category;
  final String color;
  final List<String> seasons;
  final List<String> occasions;
  final List<String> weatherSuitability; // hot, mild, cool, cold, rainy, windy
  final String? localImagePath;   // local file path (before/without Firebase)
  final String? storageImageUrl;  // Firebase Storage URL
  final bool isFavorite;
  final DateTime addedAt;
  final DateTime? lastWorn;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    this.seasons = const [],
    this.occasions = const [],
    this.weatherSuitability = const [],
    this.localImagePath,
    this.storageImageUrl,
    this.isFavorite = false,
    required this.addedAt,
    this.lastWorn,
  });

  // Effective image: prefer storage URL, fallback to local path
  String? get effectiveImagePath => storageImageUrl ?? localImagePath;

  ClothingItem copyWith({
    String? id,
    String? name,
    ClothingCategory? category,
    String? color,
    List<String>? seasons,
    List<String>? occasions,
    List<String>? weatherSuitability,
    String? localImagePath,
    String? storageImageUrl,
    bool? isFavorite,
    DateTime? addedAt,
    DateTime? lastWorn,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      seasons: seasons ?? this.seasons,
      occasions: occasions ?? this.occasions,
      weatherSuitability: weatherSuitability ?? this.weatherSuitability,
      localImagePath: localImagePath ?? this.localImagePath,
      storageImageUrl: storageImageUrl ?? this.storageImageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt ?? this.addedAt,
      lastWorn: lastWorn ?? this.lastWorn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'color': color,
        'seasons': seasons,
        'occasions': occasions,
        'weatherSuitability': weatherSuitability,
        'localImagePath': localImagePath,
        'storageImageUrl': storageImageUrl,
        'isFavorite': isFavorite,
        'addedAt': addedAt.toIso8601String(),
        'lastWorn': lastWorn?.toIso8601String(),
      };

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: ClothingCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ClothingCategory.tops,
        ),
        color: json['color'] as String,
        seasons: List<String>.from(json['seasons'] ?? []),
        occasions: List<String>.from(json['occasions'] ?? []),
        weatherSuitability: List<String>.from(json['weatherSuitability'] ?? []),
        localImagePath: json['localImagePath'] as String?,
        storageImageUrl: json['storageImageUrl'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        addedAt: DateTime.parse(json['addedAt'] as String),
        lastWorn: json['lastWorn'] != null
            ? DateTime.parse(json['lastWorn'] as String)
            : null,
      );
}
