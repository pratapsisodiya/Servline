import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/core/config/appwrite_config.dart';
import 'package:servline/core/services/appwrite_service.dart';
import 'package:servline/models/notification.dart';

class NotificationRepository {
  final Databases _databases;
  final Realtime _realtime;

  NotificationRepository(this._databases, this._realtime);

  /// Get all notifications for user
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
        ],
      );

      return result.documents
          .map((doc) => NotificationModel.fromDocument(doc))
          .toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get notifications: ${e.message}';
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollection,
        queries: [Query.equal('userId', userId), Query.equal('isRead', false)],
      );

      return result.documents.length;
    } on AppwriteException {
      return 0;
    }
  }

  /// Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType(
    String userId,
    NotificationType type, {
    int limit = 50,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('type', type.value),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
        ],
      );

      return result.documents
          .map((doc) => NotificationModel.fromDocument(doc))
          .toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get notifications: ${e.message}';
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollection,
        documentId: notificationId,
        data: {'isRead': true},
      );
    } on AppwriteException catch (e) {
      throw 'Failed to mark notification as read: ${e.message}';
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollection,
        queries: [Query.equal('userId', userId), Query.equal('isRead', false)],
      );

      for (final doc in unread.documents) {
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.notificationsCollection,
          documentId: doc.$id,
          data: {'isRead': true},
        );
      }
    } on AppwriteException catch (e) {
      throw 'Failed to mark all as read: ${e.message}';
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollection,
        documentId: notificationId,
      );
    } on AppwriteException catch (e) {
      throw 'Failed to delete notification: ${e.message}';
    }
  }

  /// Subscribe to real-time notifications
  RealtimeSubscription subscribeToNotifications(
    String userId,
    void Function(NotificationModel) onNew,
  ) {
    final subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.notificationsCollection}.documents',
    ]);

    subscription.stream.listen((event) {
      if (event.events.contains(
        'databases.*.collections.*.documents.*.create',
      )) {
        final payload = event.payload;
        if (payload['userId'] == userId) {
          final notification = NotificationModel(
            id: payload['\$id'] ?? '',
            userId: payload['userId'] ?? '',
            title: payload['title'] ?? '',
            message: payload['message'] ?? '',
            type: NotificationTypeExtension.fromString(
              payload['type'] ?? 'general',
            ),
            isRead: payload['isRead'] ?? false,
            ticketId: payload['ticketId'],
            actionText: payload['actionText'],
            actionRoute: payload['actionRoute'],
            createdAt:
                DateTime.tryParse(payload['createdAt'] ?? '') ?? DateTime.now(),
          );
          onNew(notification);
        }
      }
    });

    return subscription;
  }
}

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  final realtime = ref.watch(appwriteRealtimeProvider);
  return NotificationRepository(databases, realtime);
});
