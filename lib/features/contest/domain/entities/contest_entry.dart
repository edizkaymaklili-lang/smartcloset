import 'package:cloud_firestore/cloud_firestore.dart';

class ContestEntry {
  final String id;
  final String userId;
  final String userDisplayName;
  final String userCity;
  final String? photoPath;
  final String date; // 'YYYY-MM-DD'
  final String weatherTheme;
  final String? description;
  final int voteCount;
  final DateTime createdAt;
  final bool isVotedByMe;

  const ContestEntry({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userCity,
    this.photoPath,
    required this.date,
    required this.weatherTheme,
    this.description,
    required this.voteCount,
    required this.createdAt,
    this.isVotedByMe = false,
  });

  factory ContestEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContestEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userDisplayName: data['userDisplayName'] as String? ?? '',
      userCity: data['userCity'] as String? ?? '',
      photoPath: data['photoPath'] as String?,
      date: data['date'] as String? ?? '',
      weatherTheme: data['weatherTheme'] as String? ?? '',
      description: data['description'] as String?,
      voteCount: data['voteCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userCity': userCity,
      'photoPath': photoPath,
      'date': date,
      'weatherTheme': weatherTheme,
      'description': description,
      'voteCount': voteCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ContestEntry copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userCity,
    String? photoPath,
    String? date,
    String? weatherTheme,
    String? description,
    int? voteCount,
    DateTime? createdAt,
    bool? isVotedByMe,
  }) {
    return ContestEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userCity: userCity ?? this.userCity,
      photoPath: photoPath ?? this.photoPath,
      date: date ?? this.date,
      weatherTheme: weatherTheme ?? this.weatherTheme,
      description: description ?? this.description,
      voteCount: voteCount ?? this.voteCount,
      createdAt: createdAt ?? this.createdAt,
      isVotedByMe: isVotedByMe ?? this.isVotedByMe,
    );
  }
}
