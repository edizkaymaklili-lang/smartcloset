class WardrobeCollection {
  final String id;
  final String name;
  final String description;
  final List<String> itemIds; // ClothingItem IDs
  final DateTime createdAt;
  final String? icon; // emoji icon

  const WardrobeCollection({
    required this.id,
    required this.name,
    this.description = '',
    required this.itemIds,
    required this.createdAt,
    this.icon,
  });

  WardrobeCollection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? itemIds,
    DateTime? createdAt,
    String? icon,
  }) {
    return WardrobeCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemIds: itemIds ?? this.itemIds,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'itemIds': itemIds,
        'createdAt': createdAt.toIso8601String(),
        'icon': icon,
      };

  factory WardrobeCollection.fromJson(Map<String, dynamic> json) =>
      WardrobeCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        itemIds: List<String>.from(json['itemIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        icon: json['icon'] as String?,
      );
}
