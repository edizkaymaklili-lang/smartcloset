import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/style_feed_repository.dart';
import '../../domain/entities/style_post.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../../services/location_service.dart';
import '../../../../main.dart' show firebaseAvailableProvider;

/// Feed view mode
enum FeedMode { forYou, trending, nearby }

/// Style feed state
class StyleFeedState {
  final List<StylePost> posts;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final FeedMode mode;
  final DocumentSnapshot? lastDocument;
  final Set<String> savedPostIds;

  const StyleFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.mode = FeedMode.forYou,
    this.lastDocument,
    this.savedPostIds = const {},
  });

  StyleFeedState copyWith({
    List<StylePost>? posts,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    FeedMode? mode,
    DocumentSnapshot? lastDocument,
    Set<String>? savedPostIds,
  }) =>
      StyleFeedState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        mode: mode ?? this.mode,
        lastDocument: lastDocument ?? this.lastDocument,
        savedPostIds: savedPostIds ?? this.savedPostIds,
      );
}

/// Provider for style feed repository
final styleFeedRepositoryProvider = Provider<StyleFeedRepository>((ref) {
  return StyleFeedRepository();
});

/// Provider for location service
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider for current user ID (from Firebase Auth)
final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  // Return userId from auth state, or fallback to 'guest' if not authenticated
  return authState.userId ?? 'guest';
});

/// Style feed notifier
class StyleFeedNotifier extends Notifier<StyleFeedState> {
  late final StyleFeedRepository _repository;
  late final LocationService _locationService;
  late final String _currentUserId;

  @override
  StyleFeedState build() {
    _repository = ref.read(styleFeedRepositoryProvider);
    _locationService = ref.read(locationServiceProvider);
    _currentUserId = ref.read(currentUserIdProvider);

    // Load saved posts in background
    _loadSavedPosts();

    return const StyleFeedState();
  }

  /// Load user's saved post IDs
  Future<void> _loadSavedPosts() async {
    try {
      final savedPosts = await _repository.fetchSavedPosts(_currentUserId);
      final savedIds = savedPosts.map((post) => post.id).toSet();
      state = state.copyWith(savedPostIds: savedIds);
    } catch (e) {
      // Failed to load saved posts, continue without them
    }
  }

  /// Load initial posts
  Future<void> loadPosts({FeedMode? mode}) async {
    final newMode = mode ?? state.mode;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      mode: newMode,
      posts: [], // Clear existing posts when changing mode
      lastDocument: null,
    );

    try {
      // Wait for Firebase to be ready
      final firebaseReady = ref.read(firebaseAvailableProvider);
      if (!firebaseReady) {
        // Wait up to 5 seconds for Firebase
        for (int i = 0; i < 50; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (ref.read(firebaseAvailableProvider)) break;
        }
      }

      final posts = await _fetchPostsByMode(newMode);
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newPosts = await _fetchPostsByMode(state.mode);
      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: newPosts.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetch posts based on current mode
  Future<List<StylePost>> _fetchPostsByMode(FeedMode mode) async {
    switch (mode) {
      case FeedMode.forYou:
        return await _repository.fetchRecentPosts(
          limit: 20,
          lastDocument: state.lastDocument,
        );
      case FeedMode.trending:
        return await _repository.fetchTrendingPosts(limit: 20);
      case FeedMode.nearby:
        // Get user's current location
        final coordinates = await _locationService.getCurrentCoordinates();

        // If location is not available, return empty list
        if (coordinates == null) {
          throw Exception(
            'Location access is required for nearby feed. '
            'Please enable location permissions in your device settings.'
          );
        }

        return await _repository.fetchNearbyPosts(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          limit: 20,
        );
    }
  }

  /// Toggle like on a post
  Future<void> toggleLike(String postId) async {
    try {
      // Find the post
      final post = state.posts.firstWhere((p) => p.id == postId);
      final wasLiked = post.isLikedBy(_currentUserId);

      // Optimistic update
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          final isLiked = post.isLikedBy(_currentUserId);
          return post.copyWith(
            likes: isLiked ? post.likes - 1 : post.likes + 1,
            likedBy: isLiked
                ? post.likedBy.where((id) => id != _currentUserId).toList()
                : [...post.likedBy, _currentUserId],
          );
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);

      // Sync with backend
      await _repository.toggleLike(postId, _currentUserId);

      // Create notification if this is a like (not unlike) and not liking own post
      if (!wasLiked && _currentUserId != post.userId) {
        try {
          final authState = ref.read(authProvider);
          final notificationRepo = ref.read(notificationRepositoryProvider);
          await notificationRepo.createNotification(
            userId: post.userId,
            type: NotificationType.like,
            fromUserId: _currentUserId,
            fromUserName: authState.displayName ?? 'Someone',
            fromUserAvatar: null, // Avatar will be fetched from Firestore if needed
            postId: post.id,
            postImageUrl: post.photoUrl,
          );
        } catch (e) {
          // Don't fail the like if notification fails
        }
      }
    } catch (e) {
      // Revert on error
      state = state.copyWith(errorMessage: 'Failed to like post');
      await loadPosts(); // Refresh to get correct state
    }
  }

  /// Save/unsave a post
  Future<void> toggleSave(String postId) async {
    final isSaved = state.savedPostIds.contains(postId);

    // Optimistic update
    final newSavedIds = Set<String>.from(state.savedPostIds);
    if (isSaved) {
      newSavedIds.remove(postId);
    } else {
      newSavedIds.add(postId);
    }
    state = state.copyWith(savedPostIds: newSavedIds);

    try {
      // Sync with backend
      if (isSaved) {
        await _repository.unsavePost(postId, _currentUserId);
      } else {
        await _repository.savePost(postId, _currentUserId);
      }
    } catch (e) {
      // Revert on error
      state = state.copyWith(savedPostIds: state.savedPostIds);
      state = state.copyWith(errorMessage: 'Failed to save post');
    }
  }

  /// Create a new post
  Future<StylePost?> createPost({
    required XFile photoFile,
    String? description,
    required List<String> tags,
    PostLocation? location,
    WeatherSnapshot? weatherSnapshot,
  }) async {
    try {
      final profile = ref.read(profileProvider);
      final post = await _repository.createPost(
        userId: _currentUserId,
        userDisplayName: profile.displayName,
        photoFile: photoFile,
        description: description,
        tags: tags,
        location: location,
        weatherSnapshot: weatherSnapshot,
      );

      // Add to top of feed
      state = state.copyWith(posts: [post, ...state.posts]);

      return post;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId, _currentUserId);

      // Remove from state
      state = state.copyWith(
        posts: state.posts.where((post) => post.id != postId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Refresh feed
  Future<void> refresh() async {
    await loadPosts(mode: state.mode);
  }
}

/// Style feed provider
final styleFeedProvider =
    NotifierProvider<StyleFeedNotifier, StyleFeedState>(() {
  return StyleFeedNotifier();
});
