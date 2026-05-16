import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// Service to handle queue position alerts
class QueueAlertService {
  static final QueueAlertService _instance = QueueAlertService._internal();
  factory QueueAlertService() => _instance;
  QueueAlertService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int? _lastKnownPosition;

  /// Initialize the alert service
  /// 
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  /// Check queue position and trigger appropriate alerts
  /// Returns true if "Your Turn" screen should be shown
  Future<bool> checkQueuePosition({
    required int currentPosition,
    required String locationName,
    required BuildContext? context,
  }) async {
    // Skip if position hasn't changed
    if (_lastKnownPosition == currentPosition) {
      return false;
    }

    _lastKnownPosition = currentPosition;

    if (currentPosition == 1) {
      // Position is 1 - show "Be Ready" notification
      await _showBeReadyNotification(locationName);
      await _vibrateBriefly();
      return false;
    } else if (currentPosition == 0) {
      // Position is 0 - IT'S YOUR TURN!
      await _vibrateIntensely();
      return true; // Signal to navigate to YourTurnScreen
    }

    return false;
  }

  /// Show "Be Ready" notification when queue position is 1
  Future<void> _showBeReadyNotification(String locationName) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'queue_alerts',
          'Queue Alerts',
          channelDescription: 'Notifications for queue position updates',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/launcher_icon',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1,
      '🔔 Get Ready!',
      "You're next in line at $locationName. Please head to the waiting area.",
      notificationDetails,
    );
  }

  /// Brief vibration for "Be Ready" alert
  Future<void> _vibrateBriefly() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 300);
    }
  }

  /// Intense vibration pattern for "Your Turn" alert
  Future<void> _vibrateIntensely() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Long vibration pattern
      Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 1000],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    }
  }

  /// Cancel any ongoing vibration
  void cancelVibration() {
    Vibration.cancel();
  }

  /// Reset the last known position (call when ticket is cancelled/completed)
  void reset() {
    _lastKnownPosition = null;
  }
}

/// Global instance for easy access
final queueAlertService = QueueAlertService();
