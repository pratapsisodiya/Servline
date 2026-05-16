import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/models/app_version.dart';
import 'package:servline/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateCheckProvider = FutureProvider<AppVersion?>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return await updateService.checkForUpdates();
});

final currentVersionProvider = FutureProvider<String>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  final packageInfo = await updateService.getCurrentVersion();
  return '${packageInfo.version}+${packageInfo.buildNumber}';
});

final hasUpdateProvider = FutureProvider<bool>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return await updateService.hasUpdate();
});
