import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/models/notification.dart';
import 'package:servline/providers/auth_provider.dart';
import 'package:servline/repositories/notification_repository.dart';

/// Notification state
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notification Notifier with Appwrite integration
class NotificationNotifier extends Notifier<NotificationState> {
  RealtimeSubscription? _subscription;

  @override
  NotificationState build() {
    ref.onDispose(() {
      _subscription?.close();
    });
    return const NotificationState();
  }

  NotificationRepository get _notifRepo =>
      ref.read(notificationRepositoryProvider);

  /// Load notifications for current user
  Future<void> loadNotifications() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _notifRepo.getNotifications(user.id);
      final unreadCount = await _notifRepo.getUnreadCount(user.id);
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );

      // Subscribe to new notifications
      _subscribeToNotifications(user.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get notifications by filter
  List<NotificationModel> getFilteredNotifications(String filter) {
    switch (filter.toLowerCase()) {
      case 'important':
        return state.notifications
            .where(
              (n) =>
                  n.type == NotificationType.turnReady ||
                  n.type == NotificationType.turnApproaching,
            )
            .toList();
      case 'alerts':
        return state.notifications
            .where(
              (n) =>
                  n.type == NotificationType.queueUpdate ||
                  n.type == NotificationType.ticketCancelled,
            )
            .toList();
      default:
        return state.notifications;
    }
  }

  /// Get notifications grouped by date
  Map<String, List<NotificationModel>> getGroupedNotifications() {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notification in state.notifications) {
      final notifDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      String key;
      if (notifDate.isAtSameMomentAs(today)) {
        key = 'Today';
      } else if (notifDate.isAtSameMomentAs(yesterday)) {
        key = 'Yesterday';
      } else {
        key =
            '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}';
      }

      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return grouped;
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifRepo.markAsRead(notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final newUnreadCount = updatedNotifications
          .where((n) => !n.isRead)
          .length;
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _notifRepo.markAllAsRead(user.id);

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Subscribe to new notifications
  Future<void> _subscribeToNotifications(String userId) async {
    await _subscription?.close();
    _subscription = null;
    _subscription = _notifRepo.subscribeToNotifications(userId, (
      newNotification,
    ) {
      // Add new notification to the top of the list
      final updatedNotifications = [newNotification, ...state.notifications];
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount + 1,
      );
    });
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Notification provider
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );

/// Unread count provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
