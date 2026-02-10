import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../domain/entities/style_post.dart';
import '../domain/entities/comment.dart';

class StyleFeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Create a new style post
  Future<StylePost> createPost({
    required String userId,
    required String userDisplayName,
    String? userAvatar,
    required File photoFile,
    String? description,
    required List<String> tags,
    PostLocation? location,
    WeatherSnapshot? weatherSnapshot,
  }) async {
    try {
      // Generate post ID
      final postId = _uuid.v4();

      // Upload photo to Firebase Storage
      final photoUrl = await _uploadPhoto(userId, postId, photoFile);

      // Create post object
      final now = DateTime.now();
      final post = StylePost(
        id: postId,
        userId: userId,
        userDisplayName: userDisplayName,
        userAvatar: userAvatar,
        photoUrl: photoUrl,
        description: description,
        tags: tags,
        location: location,
        weatherSnapshot: weatherSnapshot,
        likes: 0,
        likedBy: [],
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore with geohash if location provided
      final postData = post.toJson();
      if (location != null) {
        // Add geohash field for efficient geoqueries
        final geoPoint = GeoFirePoint(location.coordinates);
        postData['geo'] = geoPoint.data;
      }

      await _firestore.collection('style_posts').doc(postId).set(postData);

      return post;
    } catch (e) {
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  /// Upload photo to Firebase Storage
  Future<String> _uploadPhoto(String userId, String postId, File file) async {
    final ref = _storage.ref().child('style_posts/$userId/$postId.jpg');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Fetch recent posts (for feed view)
  Future<List<StylePost>> fetchRecentPosts({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('style_posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => StylePost.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: ${e.toString()}');
    }
  }

  /// Fetch trending posts (last 7 days, sorted by score)
  Future<List<StylePost>> fetchTrendingPosts({int limit = 20}) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('style_posts')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .where('likes', isGreaterThanOrEqualTo: 5) // Minimum 5 likes
          .orderBy('likes', descending: true)
          .limit(limit * 2) // Fetch extra for client-side sorting
          .get();

      final posts = snapshot.docs
          .map((doc) => StylePost.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by trending score
      posts.sort((a, b) => b.trendingScore.compareTo(a.trendingScore));

      return posts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch trending posts: ${e.toString()}');
    }
  }

  /// Fetch posts near a location using geohashing for efficient queries
  Future<List<StylePost>> fetchNearbyPosts({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int limit = 20,
  }) async {
    try {
      // Create geo collection reference
      final geoCollection = GeoCollectionReference(_firestore.collection('style_posts'));

      // Create center point
      final center = GeoFirePoint(GeoPoint(latitude, longitude));

      // Query posts within radius
      final posts = <StylePost>[];

      await for (final documentList in geoCollection.subscribeWithin(
        center: center,
        radiusInKm: radiusKm,
        field: 'geo',
        geopointFrom: (data) {
          final geo = data['geo'];
          if (geo is Map && geo['geopoint'] is GeoPoint) {
            return geo['geopoint'] as GeoPoint;
          }
          // Return default geopoint if data is invalid (will be filtered out by distance)
          return const GeoPoint(0, 0);
        },
      )) {
        // Convert documents to StylePost objects
        posts.clear();
        for (final doc in documentList) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            // Only process posts that have valid geo data
            if (data['geo'] == null) continue;

            final post = StylePost.fromJson(data);
            posts.add(post);
          } catch (e) {
            // Skip malformed posts
            continue;
          }
        }

        // Sort by creation date (most recent first)
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Return first batch (stream completes after first emission for our use case)
        break;
      }

      return posts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby posts: ${e.toString()}');
    }
  }

  /// Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final docRef = _firestore.collection('style_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Post not found');
        }

        final post = StylePost.fromJson(snapshot.data()!);
        final isLiked = post.isLikedBy(userId);

        if (isLiked) {
          // Unlike
          transaction.update(docRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
            'updatedAt': Timestamp.now(),
          });
        } else {
          // Like
          transaction.update(docRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle like: ${e.toString()}');
    }
  }

  /// Save post to user's saved collection
  Future<void> savePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(postId)
          .set({
        'postId': postId,
        'savedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to save post: ${e.toString()}');
    }
  }

  /// Unsave post from user's saved collection
  Future<void> unsavePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(postId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unsave post: ${e.toString()}');
    }
  }

  /// Check if post is saved by user
  Future<bool> isPostSaved(String postId, String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .doc(postId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Fetch user's saved posts
  Future<List<StylePost>> fetchSavedPosts(String userId, {int limit = 20}) async {
    try {
      final savedSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_posts')
          .orderBy('savedAt', descending: true)
          .limit(limit)
          .get();

      if (savedSnapshot.docs.isEmpty) return [];

      final postIds = savedSnapshot.docs.map((doc) => doc.id).toList();

      // Fetch actual posts
      final posts = <StylePost>[];
      for (final postId in postIds) {
        final postDoc = await _firestore.collection('style_posts').doc(postId).get();
        if (postDoc.exists) {
          posts.add(StylePost.fromJson(postDoc.data()!));
        }
      }

      return posts;
    } catch (e) {
      throw Exception('Failed to fetch saved posts: ${e.toString()}');
    }
  }

  /// Delete a post (only by post owner)
  Future<void> deletePost(String postId, String userId) async {
    try {
      final docRef = _firestore.collection('style_posts').doc(postId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        throw Exception('Post not found');
      }

      final post = StylePost.fromJson(snapshot.data()!);
      if (post.userId != userId) {
        throw Exception('Unauthorized: You can only delete your own posts');
      }

      // Delete photo from Storage
      try {
        await _storage.refFromURL(post.photoUrl).delete();
      } catch (_) {
        // Photo might already be deleted, continue
      }

      // Delete post document
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete post: ${e.toString()}');
    }
  }

  /// Fetch posts by a specific user
  Future<List<StylePost>> fetchUserPosts(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('style_posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => StylePost.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user posts: ${e.toString()}');
    }
  }

  // ==================== COMMENTS ====================

  /// Add a comment to a post
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String userDisplayName,
    String? userAvatar,
    required String text,
  }) async {
    try {
      final commentId = _uuid.v4();
      final now = DateTime.now();

      final comment = Comment(
        id: commentId,
        postId: postId,
        userId: userId,
        userDisplayName: userDisplayName,
        userAvatar: userAvatar,
        text: text,
        createdAt: now,
      );

      await _firestore
          .collection('style_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toJson());

      return comment;
    } catch (e) {
      throw Exception('Failed to add comment: ${e.toString()}');
    }
  }

  /// Fetch comments for a post
  Future<List<Comment>> fetchComments(String postId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('style_posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false) // Oldest first
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Comment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: ${e.toString()}');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId, String userId) async {
    try {
      final docRef = _firestore
          .collection('style_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw Exception('Comment not found');
      }

      final comment = Comment.fromJson(snapshot.data()!);
      if (comment.userId != userId) {
        throw Exception('Unauthorized: You can only delete your own comments');
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete comment: ${e.toString()}');
    }
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike(String postId, String commentId, String userId) async {
    try {
      final docRef = _firestore
          .collection('style_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Comment not found');
        }

        final comment = Comment.fromJson(snapshot.data()!);
        final isLiked = comment.isLikedBy(userId);

        if (isLiked) {
          // Unlike
          transaction.update(docRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
          });
        } else {
          // Like
          transaction.update(docRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: ${e.toString()}');
    }
  }
}
