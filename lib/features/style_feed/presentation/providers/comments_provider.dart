import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/comment.dart';
import '../../data/style_feed_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'style_feed_provider.dart';

/// Comments provider for a specific post
/// Usage: ref.watch(commentsProvider(postId))
final commentsProvider = FutureProvider.autoDispose.family<List<Comment>, String>((ref, postId) async {
  final repository = ref.read(styleFeedRepositoryProvider);
  return await repository.fetchComments(postId);
});

/// Add comment to a post
final addCommentProvider = Provider((ref) {
  return ({
    required String postId,
    required String text,
  }) async {
    final repository = ref.read(styleFeedRepositoryProvider);
    final currentUserId = ref.read(currentUserIdProvider);
    final authState = ref.read(authProvider);

    await repository.addComment(
      postId: postId,
      userId: currentUserId,
      userDisplayName: authState.displayName ?? 'Anonymous',
      userAvatar: null,
      text: text,
    );

    // Invalidate to refresh comments
    ref.invalidate(commentsProvider(postId));
  };
});

/// Delete comment from a post
final deleteCommentProvider = Provider((ref) {
  return ({
    required String postId,
    required String commentId,
  }) async {
    final repository = ref.read(styleFeedRepositoryProvider);
    final currentUserId = ref.read(currentUserIdProvider);

    await repository.deleteComment(postId, commentId, currentUserId);

    // Invalidate to refresh comments
    ref.invalidate(commentsProvider(postId));
  };
});

/// Toggle like on a comment
final toggleCommentLikeProvider = Provider((ref) {
  return ({
    required String postId,
    required String commentId,
  }) async {
    final repository = ref.read(styleFeedRepositoryProvider);
    final currentUserId = ref.read(currentUserIdProvider);

    await repository.toggleCommentLike(postId, commentId, currentUserId);

    // Invalidate to refresh comments
    ref.invalidate(commentsProvider(postId));
  };
});
