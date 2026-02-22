import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Stream provider for user's notifications
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(authProvider).userId;
  if (userId == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUserNotificationsStream(userId);
});

/// Stream provider for unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(authProvider).userId;
  if (userId == null) {
    return Stream.value(0);
  }
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCountStream(userId);
});

/// Notification actions provider
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  final Ref ref;
  NotificationActions(this.ref);

  Future<void> markAsRead(String notificationId) async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAllAsRead(userId);
  }

  Future<void> deleteNotification(String notificationId) async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.deleteNotification(notificationId);
  }

  Future<void> deleteAllNotifications() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    final repository = ref.read(notificationRepositoryProvider);
    await repository.deleteAllNotifications(userId);
  }

  /// Create notification (used by other features)
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String fromUserId,
    required String fromUserName,
    String? fromUserAvatar,
    String? postId,
    String? postImageUrl,
    String? commentText,
  }) async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.createNotification(
      userId: userId,
      type: type,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserAvatar: fromUserAvatar,
      postId: postId,
      postImageUrl: postImageUrl,
      commentText: commentText,
    );
  }
}
