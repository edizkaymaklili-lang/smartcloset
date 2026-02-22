import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../notifications/domain/entities/notification.dart';

class FollowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepo = NotificationRepository();

  /// Follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) {
      throw Exception('Cannot follow yourself');
    }

    final batch = _firestore.batch();

    // Add to current user's following list
    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    batch.set(followingRef, {
      'userId': targetUserId,
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Add to target user's followers list
    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    batch.set(followerRef, {
      'userId': currentUserId,
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Update follower/following counts
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    batch.update(currentUserRef, {
      'followingCount': FieldValue.increment(1),
    });

    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    batch.update(targetUserRef, {
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();

    // Create notification for the followed user
    try {
      // Get current user's info for the notification
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final currentUserData = currentUserDoc.data();

      await _notificationRepo.createNotification(
        userId: targetUserId,
        type: NotificationType.follow,
        fromUserId: currentUserId,
        fromUserName: currentUserData?['displayName'] ?? 'Someone',
        fromUserAvatar: currentUserData?['avatarPath'],
      );
    } catch (e) {
      debugPrint('Error creating follow notification: $e');
      // Don't fail the follow operation if notification fails
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();

    // Remove from current user's following list
    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    batch.delete(followingRef);

    // Remove from target user's followers list
    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    batch.delete(followerRef);

    // Update follower/following counts
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    batch.update(currentUserRef, {
      'followingCount': FieldValue.increment(-1),
    });

    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    batch.update(targetUserRef, {
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Check if currentUser is following targetUser
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Get list of users that currentUser is following
  Future<List<String>> getFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching following list: $e');
      return [];
    }
  }

  /// Get list of users following currentUser
  Future<List<String>> getFollowers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching followers list: $e');
      return [];
    }
  }

  /// Get follower/following counts for a user
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'followers': 0, 'following': 0};
      }
      final data = userDoc.data();
      return {
        'followers': data?['followersCount'] ?? 0,
        'following': data?['followingCount'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching follow counts: $e');
      return {'followers': 0, 'following': 0};
    }
  }

  /// Stream of followers count
  Stream<int> followersCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      return doc.data()?['followersCount'] ?? 0;
    });
  }

  /// Stream of following count
  Stream<int> followingCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      return doc.data()?['followingCount'] ?? 0;
    });
  }

  /// Stream to check if following
  Stream<bool> isFollowingStream(String currentUserId, String targetUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
