import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/follow_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

/// Provider to check if current user is following a specific user
final isFollowingProvider =
    StreamProvider.family<bool, String>((ref, targetUserId) {
  final currentUserId = ref.watch(authProvider).userId;
  if (currentUserId == null) {
    return Stream.value(false);
  }
  final repository = ref.watch(followRepositoryProvider);
  return repository.isFollowingStream(currentUserId, targetUserId);
});

/// Provider for followers count of a user
final followersCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final repository = ref.watch(followRepositoryProvider);
  return repository.followersCountStream(userId);
});

/// Provider for following count of a user
final followingCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final repository = ref.watch(followRepositoryProvider);
  return repository.followingCountStream(userId);
});

/// Notifier for follow actions
final followActionsProvider =
    Provider<FollowActionsNotifier>((ref) {
  return FollowActionsNotifier(ref);
});

class FollowActionsNotifier {
  final Ref ref;
  FollowActionsNotifier(this.ref);

  Future<void> toggleFollow(String targetUserId) async {
    final currentUserId = ref.read(authProvider).userId;
    if (currentUserId == null) {
      throw Exception('Must be logged in to follow users');
    }

    final repository = ref.read(followRepositoryProvider);
    final isFollowing = await repository.isFollowing(currentUserId, targetUserId);

    if (isFollowing) {
      await repository.unfollowUser(currentUserId, targetUserId);
    } else {
      await repository.followUser(currentUserId, targetUserId);
    }
  }

  Future<List<String>> getFollowers(String userId) async {
    final repository = ref.read(followRepositoryProvider);
    return repository.getFollowers(userId);
  }

  Future<List<String>> getFollowing(String userId) async {
    final repository = ref.read(followRepositoryProvider);
    return repository.getFollowing(userId);
  }
}
