import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/providers/update_provider.dart';
import 'package:servline/widgets/update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateChecker {
  static const String _lastCheckKey = 'last_update_check';
  static const Duration _checkInterval = Duration(hours: 6);

  static Future<void> checkForUpdates(
    BuildContext context,
    WidgetRef ref, {
    bool force = false,
  }) async {
    if (!force && !await _shouldCheck()) {
      return;
    }

    final updateAsync = ref.read(updateCheckProvider);

    updateAsync.when(
      data: (version) async {
        if (version != null) {
          final currentVersionAsync = await ref.read(currentVersionProvider.future);
          final parts = currentVersionAsync.split('+');
          final currentVersion = parts[0];
          final currentBuild = parts.length > 1 ? parts[1] : '1';

          if (version.isNewerThan(currentVersion, currentBuild)) {
            if (context.mounted) {
              await showDialog(
                context: context,
                barrierDismissible: !version.forceUpdate,
                builder: (context) => UpdateDialog(
                  version: version,
                  forceUpdate: version.forceUpdate,
                ),
              );
            }
          }
        }
        await _markChecked();
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  static Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey);

    if (lastCheck == null) {
      return true;
    }

    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    final now = DateTime.now();

    return now.difference(lastCheckTime) >= _checkInterval;
  }

  static Future<void> _markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> resetCheckTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCheckKey);
  }
}
