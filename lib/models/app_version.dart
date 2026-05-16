class AppVersion {
  final String version;
  final String buildNumber;
  final String downloadUrl;
  final bool forceUpdate;
  final String? releaseNotes;
  final DateTime releasedAt;

  AppVersion({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.forceUpdate = false,
    this.releaseNotes,
    required this.releasedAt,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as String,
      downloadUrl: json['downloadUrl'] as String,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      releaseNotes: json['releaseNotes'] as String?,
      releasedAt: DateTime.parse(json['releasedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'downloadUrl': downloadUrl,
      'forceUpdate': forceUpdate,
      'releaseNotes': releaseNotes,
      'releasedAt': releasedAt.toIso8601String(),
    };
  }

  bool isNewerThan(String currentVersion, String currentBuildNumber) {
    final currentBuild = int.tryParse(currentBuildNumber) ?? 0;
    final latestBuild = int.tryParse(buildNumber) ?? 0;
    return latestBuild > currentBuild;
  }
}
