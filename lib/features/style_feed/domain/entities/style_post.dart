import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Location data for a style post
class PostLocation extends Equatable {
  final GeoPoint coordinates;
  final String city;
  final String country;
  final bool isExactLocation;

  const PostLocation({
    required this.coordinates,
    required this.city,
    required this.country,
    required this.isExactLocation,
  });

  Map<String, dynamic> toJson() => {
        'coordinates': coordinates,
        'city': city,
        'country': country,
        'isExactLocation': isExactLocation,
      };

  factory PostLocation.fromJson(Map<String, dynamic> json) => PostLocation(
        coordinates: json['coordinates'] as GeoPoint,
        city: json['city'] as String,
        country: json['country'] as String,
        isExactLocation: json['isExactLocation'] as bool,
      );

  @override
  List<Object?> get props => [coordinates, city, country, isExactLocation];
}

/// Weather snapshot at the time of posting
class WeatherSnapshot extends Equatable {
  final double temp;
  final String description;
  final String icon;

  const WeatherSnapshot({
    required this.temp,
    required this.description,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'temp': temp,
        'description': description,
        'icon': icon,
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) =>
      WeatherSnapshot(
        temp: (json['temp'] as num).toDouble(),
        description: json['description'] as String,
        icon: json['icon'] as String,
      );

  @override
  List<Object?> get props => [temp, description, icon];
}

/// Main style post entity
class StylePost extends Equatable {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userAvatar;
  final String photoUrl;
  final String? description;
  final List<String> tags;
  final PostLocation? location;
  final WeatherSnapshot? weatherSnapshot;
  final int likes;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StylePost({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userAvatar,
    required this.photoUrl,
    this.description,
    required this.tags,
    this.location,
    this.weatherSnapshot,
    required this.likes,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if current user has liked this post
  bool isLikedBy(String currentUserId) => likedBy.contains(currentUserId);

  /// Calculate trending score (Reddit-like algorithm)
  double get trendingScore {
    final hoursSincePost = DateTime.now().difference(createdAt).inHours;
    final timeDecay = (hoursSincePost + 2) * (hoursSincePost + 2) * (hoursSincePost + 2).toDouble(); // ^1.5 approximation
    return likes / timeDecay;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userAvatar': userAvatar,
        'photoUrl': photoUrl,
        'description': description,
        'tags': tags,
        'location': location?.toJson(),
        'weatherSnapshot': weatherSnapshot?.toJson(),
        'likes': likes,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory StylePost.fromJson(Map<String, dynamic> json) => StylePost(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userDisplayName: json['userDisplayName'] as String,
        userAvatar: json['userAvatar'] as String?,
        photoUrl: json['photoUrl'] as String,
        description: json['description'] as String?,
        tags: List<String>.from(json['tags'] as List),
        location: json['location'] != null
            ? PostLocation.fromJson(json['location'] as Map<String, dynamic>)
            : null,
        weatherSnapshot: json['weatherSnapshot'] != null
            ? WeatherSnapshot.fromJson(
                json['weatherSnapshot'] as Map<String, dynamic>)
            : null,
        likes: json['likes'] as int,
        likedBy: List<String>.from(json['likedBy'] as List),
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      );

  StylePost copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userAvatar,
    String? photoUrl,
    String? description,
    List<String>? tags,
    PostLocation? location,
    WeatherSnapshot? weatherSnapshot,
    int? likes,
    List<String>? likedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      StylePost(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userDisplayName: userDisplayName ?? this.userDisplayName,
        userAvatar: userAvatar ?? this.userAvatar,
        photoUrl: photoUrl ?? this.photoUrl,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        location: location ?? this.location,
        weatherSnapshot: weatherSnapshot ?? this.weatherSnapshot,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        userDisplayName,
        userAvatar,
        photoUrl,
        description,
        tags,
        location,
        weatherSnapshot,
        likes,
        likedBy,
        createdAt,
        updatedAt,
      ];
}
