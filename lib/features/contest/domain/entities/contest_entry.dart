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
