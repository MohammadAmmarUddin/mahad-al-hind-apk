class AppUpdateConfig {
  final String latestVersion;
  final String minVersion;
  final bool forceUpdate;
  final String apkUrl;
  final String releaseNotes;
  final bool updateEnabled;

  const AppUpdateConfig({
    this.latestVersion = '',
    this.minVersion = '',
    this.forceUpdate = false,
    this.apkUrl = '',
    this.releaseNotes = '',
    this.updateEnabled = true,
  });

  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) {
    return AppUpdateConfig(
      latestVersion: json['latestVersion']?.toString() ?? '',
      minVersion: json['minVersion']?.toString() ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
      apkUrl: json['apkUrl']?.toString() ?? '',
      releaseNotes: json['releaseNotes']?.toString() ?? '',
      updateEnabled: json['updateEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'latestVersion': latestVersion,
    'minVersion': minVersion,
    'forceUpdate': forceUpdate,
    'apkUrl': apkUrl,
    'releaseNotes': releaseNotes,
    'updateEnabled': updateEnabled,
  };
}
