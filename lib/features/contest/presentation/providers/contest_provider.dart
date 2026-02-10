import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/weather_condition.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../data/contest_mock_datasource.dart';
import '../../domain/entities/contest_entry.dart';

// ── Weather theme label ──────────────────────────────────────────────────────
String _weatherTheme(WeatherClass? wc) => switch (wc) {
      WeatherClass.hotSunny => 'Summer Glow ☀️',
      WeatherClass.mildWarm => 'Spring Breeze 🌸',
      WeatherClass.cool => 'Autumn Layers 🍂',
      WeatherClass.windyCool => 'Wind-Proof Chic 💨',
      WeatherClass.rainy => 'Rainy Day Style 🌧️',
      WeatherClass.snowyCold => 'Winter Wonderland ❄️',
      null => 'Daily Style 👗',
    };

// ── Device user identity (no auth needed for mock) ──────────────────────────
final deviceUserIdProvider = Provider<String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  var id = prefs.getString('device_user_id');
  if (id == null) {
    id = const Uuid().v4();
    prefs.setString('device_user_id', id);
  }
  return id;
});

// ── Current weather theme ───────────────────────────────────────────────────
final contestThemeProvider = Provider<String>((ref) {
  final weatherAsync = ref.watch(weatherProvider);
  return weatherAsync.when(
    data: (w) {
      // Simple classify inline
      WeatherClass wc;
      if (w.precipitation > 2) {
        wc = WeatherClass.rainy;
      } else if (w.temperature < 2) {
        wc = WeatherClass.snowyCold;
      } else if (w.windSpeed > 8 && w.temperature < 15) {
        wc = WeatherClass.windyCool;
      } else if (w.temperature >= 25) {
        wc = WeatherClass.hotSunny;
      } else if (w.temperature >= 15) {
        wc = WeatherClass.mildWarm;
      } else {
        wc = WeatherClass.cool;
      }
      return _weatherTheme(wc);
    },
    loading: () => 'Daily Style 👗',
    error: (_, st) => 'Daily Style 👗',
  );
});

// ── Contest state ────────────────────────────────────────────────────────────
class ContestState {
  final List<ContestEntry> entries;
  final ContestEntry? yesterdayWinner;
  final Set<String> votedIds;
  final bool isSubmitting;

  const ContestState({
    this.entries = const [],
    this.yesterdayWinner,
    this.votedIds = const {},
    this.isSubmitting = false,
  });

  ContestState copyWith({
    List<ContestEntry>? entries,
    ContestEntry? yesterdayWinner,
    Set<String>? votedIds,
    bool? isSubmitting,
  }) {
    return ContestState(
      entries: entries ?? this.entries,
      yesterdayWinner: yesterdayWinner ?? this.yesterdayWinner,
      votedIds: votedIds ?? this.votedIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final contestProvider = NotifierProvider<ContestNotifier, ContestState>(() {
  return ContestNotifier();
});

class ContestNotifier extends Notifier<ContestState> {
  static const _keyVotedEntries = 'voted_contest_entries';

  @override
  ContestState build() {
    final theme = ref.watch(contestThemeProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final votedList = prefs.getStringList(_keyVotedEntries) ?? [];
    final votedSet = Set<String>.from(votedList);

    final entries = ContestMockDatasource.getTodayEntries(theme)
        .map((e) => e.copyWith(isVotedByMe: votedSet.contains(e.id)))
        .toList();

    return ContestState(
      entries: entries,
      yesterdayWinner: ContestMockDatasource.getYesterdayWinner(),
      votedIds: votedSet,
    );
  }

  void toggleVote(String entryId) {
    final prefs = ref.read(sharedPreferencesProvider);
    final votedSet = Set<String>.from(state.votedIds);

    final isVoted = votedSet.contains(entryId);
    if (isVoted) {
      votedSet.remove(entryId);
    } else {
      votedSet.add(entryId);
    }

    prefs.setStringList(_keyVotedEntries, votedSet.toList());

    final updatedEntries = state.entries.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        voteCount: isVoted ? e.voteCount - 1 : e.voteCount + 1,
        isVotedByMe: !isVoted,
      );
    }).toList();

    state = state.copyWith(entries: updatedEntries, votedIds: votedSet);
  }

  void submitEntry({
    required String displayName,
    required String city,
    required String? photoPath,
    required String? description,
  }) {
    final deviceId = ref.read(deviceUserIdProvider);
    final theme = ref.read(contestThemeProvider);

    final newEntry = ContestEntry(
      id: const Uuid().v4(),
      userId: deviceId,
      userDisplayName: displayName,
      userCity: city,
      photoPath: photoPath,
      date: ContestMockDatasource.todayDate(),
      weatherTheme: theme,
      description: description,
      voteCount: 0,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(entries: [...state.entries, newEntry]);
  }
}
