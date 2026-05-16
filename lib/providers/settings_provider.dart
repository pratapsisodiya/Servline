import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings state
class SettingsState {
  final bool notificationSounds;
  final bool vibration;
  final bool darkMode;
  final double textSize;
  final bool isLoading;

  const SettingsState({
    this.notificationSounds = true,
    this.vibration = true,
    this.darkMode = false,
    this.textSize = 1.0,
    this.isLoading = true,
  });

  SettingsState copyWith({
    bool? notificationSounds,
    bool? vibration,
    bool? darkMode,
    double? textSize,
    bool? isLoading,
  }) {
    return SettingsState(
      notificationSounds: notificationSounds ?? this.notificationSounds,
      vibration: vibration ?? this.vibration,
      darkMode: darkMode ?? this.darkMode,
      textSize: textSize ?? this.textSize,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Settings Notifier
class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _keyNotificationSounds = 'settings_notification_sounds';
  static const _keyVibration = 'settings_vibration';
  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyTextSize = 'settings_text_size';

  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      notificationSounds: prefs.getBool(_keyNotificationSounds) ?? true,
      vibration: prefs.getBool(_keyVibration) ?? true,
      darkMode: prefs.getBool(_keyDarkMode) ?? false,
      textSize: prefs.getDouble(_keyTextSize) ?? 1.0,
      isLoading: false,
    );
  }

  Future<void> toggleNotificationSounds(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationSounds, value);
    state = AsyncValue.data(state.requireValue.copyWith(notificationSounds: value));
  }

  Future<void> toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibration, value);
    state = AsyncValue.data(state.requireValue.copyWith(vibration: value));
  }

  Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    state = AsyncValue.data(state.requireValue.copyWith(darkMode: value));
  }

  Future<void> setTextSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextSize, value);
    state = AsyncValue.data(state.requireValue.copyWith(textSize: value));
  }
}

/// Settings provider
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
