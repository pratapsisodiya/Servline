import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/core/theme/app_theme.dart';
import 'package:servline/models/notification.dart';
import 'package:servline/providers/notification_provider.dart';
import 'package:servline/widgets/notification_tile.dart';

/// Notifications Hub Screen - as per design screenshot
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Important', 'Alerts'];

  @override
  void initState() {
    super.initState();
    // Load notifications on init
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    // Get filtered and grouped notifications
    final filteredNotifications = notifier.getFilteredNotifications(
      _selectedFilter,
    );
    final groupedNotifications = _groupByDate(filteredNotifications);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => notifier.markAllAsRead(),
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Notifications List
          Expanded(
            child: notifState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groupedNotifications.length,
                    itemBuilder: (context, index) {
                      final entry = groupedNotifications.entries.elementAt(
                        index,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          DateSectionHeader(date: entry.key),
                          // Notifications for this date
                          ...entry.value.map(
                            (notification) => NotificationTile(
                              notification: notification,
                              onTap: () {
                                notifier.markAsRead(notification.id);
                                if (notification.ticketId != null) {
                                  context.push('/active-ticket');
                                }
                              },
                              onActionTap: () {
                                if (notification.actionRoute != null) {
                                  context.push(notification.actionRoute!);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, List<NotificationModel>> _groupByDate(
    List<NotificationModel> notifications,
  ) {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notification in notifications) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text('No notifications', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('You\'re all caught up!', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
