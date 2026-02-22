import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/contest_entry.dart';

class ContestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _yesterdayDate() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  /// Returns today's contest ID (date string), creating the document if needed.
  Future<String> getOrCreateTodayContest(String theme) async {
    final today = _todayDate();
    final ref = _firestore.collection('contests').doc(today);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'theme': theme,
        'date': today,
        'isActive': true,
        'winnerId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return today;
  }

  /// Real-time stream of today's entries ordered by voteCount descending.
  Stream<List<ContestEntry>> getEntriesStream(String contestId) {
    return _firestore
        .collection('contests')
        .doc(contestId)
        .collection('entries')
        .orderBy('voteCount', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ContestEntry.fromFirestore).toList());
  }

  /// Returns the winner from yesterday's contest (highest vote count).
  Future<ContestEntry?> getYesterdayWinner() async {
    final yesterday = _yesterdayDate();
    final snap = await _firestore
        .collection('contests')
        .doc(yesterday)
        .collection('entries')
        .orderBy('voteCount', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ContestEntry.fromFirestore(snap.docs.first);
  }

  /// Adds a new entry to the given contest.
  Future<void> submitEntry({
    required String contestId,
    required ContestEntry entry,
  }) async {
    await _firestore
        .collection('contests')
        .doc(contestId)
        .collection('entries')
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  /// Atomically toggles a vote. Returns true if vote was added, false if removed.
  Future<bool> toggleVote({
    required String contestId,
    required String entryId,
    required String userId,
  }) async {
    final voterRef = _firestore
        .collection('votes')
        .doc(entryId)
        .collection('voters')
        .doc(userId);
    final entryRef = _firestore
        .collection('contests')
        .doc(contestId)
        .collection('entries')
        .doc(entryId);

    bool voteAdded = false;
    await _firestore.runTransaction((txn) async {
      final voterSnap = await txn.get(voterRef);
      if (voterSnap.exists) {
        txn.delete(voterRef);
        txn.update(entryRef, {'voteCount': FieldValue.increment(-1)});
        voteAdded = false;
      } else {
        txn.set(voterRef, {'votedAt': FieldValue.serverTimestamp()});
        txn.update(entryRef, {'voteCount': FieldValue.increment(1)});
        voteAdded = true;
      }
    });
    return voteAdded;
  }
}
