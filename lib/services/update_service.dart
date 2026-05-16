import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:servline/models/app_version.dart';

class UpdateService {
  static const String _updateCheckUrl =
      'https://api.github.com/repos/pratapsisodiya/Servline/releases/latest';

  Future<PackageInfo> getCurrentVersion() async {
    return await PackageInfo.fromPlatform();
  }

  Future<AppVersion?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_updateCheckUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract version from tag_name (e.g., "v1.0.1" -> "1.0.1")
        final tagName = data['tag_name'] as String? ?? '';
        final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

        // Parse build number from version (e.g., "1.0.1" -> build "1")
        final versionParts = version.split('+');
        final versionNumber = versionParts[0];
        final buildNumber = versionParts.length > 1 ? versionParts[1] : '1';

        // Find APK download URL from assets
        final assets = data['assets'] as List<dynamic>? ?? [];
        String? apkUrl;

        for (var asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk') && name.contains('arm64-v8a')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }

        if (apkUrl == null) {
          // Fallback to first APK found
          for (var asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }

        if (apkUrl == null) {
          return null;
        }

        return AppVersion(
          version: versionNumber,
          buildNumber: buildNumber,
          downloadUrl: apkUrl,
          forceUpdate: false,
          releaseNotes: data['body'] as String?,
          releasedAt: DateTime.parse(data['published_at'] as String),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasUpdate() async {
    final currentVersion = await getCurrentVersion();
    final latestVersion = await checkForUpdates();

    if (latestVersion == null) {
      return false;
    }

    return latestVersion.isNewerThan(
      currentVersion.version,
      currentVersion.buildNumber,
    );
  }
}
