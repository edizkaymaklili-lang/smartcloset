import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/weather_condition.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../data/contest_repository.dart';
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

// ── Contest repository provider ──────────────────────────────────────────────
final contestRepositoryProvider = Provider<ContestRepository>((ref) {
  return ContestRepository();
});

// ── Current weather theme ───────────────────────────────────────────────────
final contestThemeProvider = Provider<String>((ref) {
  final weatherAsync = ref.watch(weatherProvider);
  return weatherAsync.when(
    data: (w) {
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
    error: (_, _) => 'Daily Style 👗',
  );
});

// ── Contest state ────────────────────────────────────────────────────────────
class ContestState {
  final List<ContestEntry> entries;
  final ContestEntry? yesterdayWinner;
  final Set<String> votedIds;
  final bool isSubmitting;
  final String? contestId;

  const ContestState({
    this.entries = const [],
    this.yesterdayWinner,
    this.votedIds = const {},
    this.isSubmitting = false,
    this.contestId,
  });

  ContestState copyWith({
    List<ContestEntry>? entries,
    ContestEntry? yesterdayWinner,
    Set<String>? votedIds,
    bool? isSubmitting,
    String? contestId,
  }) {
    return ContestState(
      entries: entries ?? this.entries,
      yesterdayWinner: yesterdayWinner ?? this.yesterdayWinner,
      votedIds: votedIds ?? this.votedIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      contestId: contestId ?? this.contestId,
    );
  }
}

final contestProvider = NotifierProvider<ContestNotifier, ContestState>(() {
  return ContestNotifier();
});

class ContestNotifier extends Notifier<ContestState> {
  static const _keyVotedEntries = 'voted_contest_entries';
  StreamSubscription<List<ContestEntry>>? _entriesSubscription;

  @override
  ContestState build() {
    final theme = ref.watch(contestThemeProvider);

    // Load voted IDs from local storage for fast initial state
    final prefs = ref.read(sharedPreferencesProvider);
    final votedSet = Set<String>.from(
      prefs.getStringList(_keyVotedEntries) ?? [],
    );

    // Clean up stream on rebuild/dispose
    ref.onDispose(() => _entriesSubscription?.cancel());

    // Kick off async Firestore load
    _loadAsync(theme, votedSet);

    return ContestState(votedIds: votedSet);
  }

  Future<void> _loadAsync(String theme, Set<String> initialVotedIds) async {
    final repo = ref.read(contestRepositoryProvider);
    try {
      final contestId = await repo.getOrCreateTodayContest(theme);
      state = state.copyWith(contestId: contestId);

      // Load yesterday's winner
      final winner = await repo.getYesterdayWinner();
      if (winner != null) {
        state = state.copyWith(yesterdayWinner: winner);
      }

      // Subscribe to live entries stream
      _entriesSubscription?.cancel();
      _entriesSubscription =
          repo.getEntriesStream(contestId).listen((entries) {
        final updatedEntries = entries
            .map((e) => e.copyWith(isVotedByMe: state.votedIds.contains(e.id)))
            .toList();
        state = state.copyWith(entries: updatedEntries);
      });
    } catch (_) {
      // Firebase not ready — entries stay empty, will retry on next build
    }
  }

  Future<void> toggleVote(String entryId) async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final isVoted = state.votedIds.contains(entryId);

    // Optimistic UI update
    final newVotedIds = Set<String>.from(state.votedIds);
    if (isVoted) {
      newVotedIds.remove(entryId);
    } else {
      newVotedIds.add(entryId);
    }
    prefs.setStringList(_keyVotedEntries, newVotedIds.toList());

    final updatedEntries = state.entries.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        voteCount: isVoted ? e.voteCount - 1 : e.voteCount + 1,
        isVotedByMe: !isVoted,
      );
    }).toList();
    state = state.copyWith(entries: updatedEntries, votedIds: newVotedIds);

    // Firestore update (best-effort — optimistic update already applied)
    final contestId = state.contestId;
    if (contestId == null) return;
    try {
      await ref.read(contestRepositoryProvider).toggleVote(
            contestId: contestId,
            entryId: entryId,
            userId: userId,
          );
    } catch (_) {
      // Network error — local state remains as-is
    }
  }

  Future<void> submitEntry({
    required String displayName,
    required String city,
    required String? photoPath,
    required String? description,
  }) async {
    final userId = ref.read(authProvider).userId;
    final theme = ref.read(contestThemeProvider);
    final contestId = state.contestId;

    state = state.copyWith(isSubmitting: true);

    final newEntry = ContestEntry(
      id: const Uuid().v4(),
      userId: userId ?? 'anonymous',
      userDisplayName: displayName,
      userCity: city,
      photoPath: photoPath,
      date: contestId ?? _todayDate(),
      weatherTheme: theme,
      description: description,
      voteCount: 0,
      createdAt: DateTime.now(),
    );

    try {
      if (contestId != null) {
        await ref.read(contestRepositoryProvider).submitEntry(
              contestId: contestId,
              entry: newEntry,
            );
      }
      // Optimistic local add (stream will confirm)
      state = state.copyWith(
        entries: [...state.entries, newEntry],
        isSubmitting: false,
      );
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
    }
  }

  static String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
