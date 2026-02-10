import '../domain/entities/contest_entry.dart';

class ContestMockDatasource {
  static String todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String yesterdayDate() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  static List<ContestEntry> getTodayEntries(String weatherTheme) {
    final today = todayDate();
    return [
      ContestEntry(
        id: 'mock_1',
        userId: 'user_istanbul',
        userDisplayName: 'Ayse K.',
        userCity: 'Istanbul, TR',
        date: today,
        weatherTheme: weatherTheme,
        description: 'Layered look with my favorite trench coat ✨',
        voteCount: 47,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ContestEntry(
        id: 'mock_2',
        userId: 'user_paris',
        userDisplayName: 'Léa M.',
        userCity: 'Paris, FR',
        date: today,
        weatherTheme: weatherTheme,
        description: 'Classic French girl aesthetic 🥐',
        voteCount: 38,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      ContestEntry(
        id: 'mock_3',
        userId: 'user_nyc',
        userDisplayName: 'Sarah J.',
        userCity: 'New York, US',
        date: today,
        weatherTheme: weatherTheme,
        description: 'NYC street style all the way 🗽',
        voteCount: 31,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ContestEntry(
        id: 'mock_4',
        userId: 'user_tokyo',
        userDisplayName: 'Yuki T.',
        userCity: 'Tokyo, JP',
        date: today,
        weatherTheme: weatherTheme,
        description: 'Harajuku inspired with a modern twist 🌸',
        voteCount: 29,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ContestEntry(
        id: 'mock_5',
        userId: 'user_milan',
        userDisplayName: 'Sofia R.',
        userCity: 'Milan, IT',
        date: today,
        weatherTheme: weatherTheme,
        description: 'La dolce vita vibes 💛',
        voteCount: 24,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ContestEntry(
        id: 'mock_6',
        userId: 'user_london',
        userDisplayName: 'Emma W.',
        userCity: 'London, UK',
        date: today,
        weatherTheme: weatherTheme,
        description: 'British chic meets contemporary 🫖',
        voteCount: 19,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ContestEntry(
        id: 'mock_7',
        userId: 'user_seoul',
        userDisplayName: 'Ji-Yeon P.',
        userCity: 'Seoul, KR',
        date: today,
        weatherTheme: weatherTheme,
        description: 'K-style minimalist look 🍃',
        voteCount: 15,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ContestEntry(
        id: 'mock_8',
        userId: 'user_sydney',
        userDisplayName: 'Olivia B.',
        userCity: 'Sydney, AU',
        date: today,
        weatherTheme: weatherTheme,
        description: 'Beach to street transition 🌊',
        voteCount: 8,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  static ContestEntry? getYesterdayWinner() {
    return ContestEntry(
      id: 'winner_yesterday',
      userId: 'user_istanbul',
      userDisplayName: 'Ayse K.',
      userCity: 'Istanbul, TR',
      date: yesterdayDate(),
      weatherTheme: 'Autumn Layers',
      description: 'Winning look from yesterday! 🏆',
      voteCount: 63,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    );
  }
}
