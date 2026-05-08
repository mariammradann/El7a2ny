class DeviceStatus {
  const DeviceStatus({
    required this.smartwatchConnected,
    required this.homeSensorConnected,
  });

  final bool smartwatchConnected;
  final bool homeSensorConnected;

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      smartwatchConnected: _readBool(json, const [
        'smartwatchConnected',       // ← camelCase (what Django currently returns)
        'smartwatch_connected',
        'smartwatch',
        'watch_connected',
      ]),
      homeSensorConnected: _readBool(json, const [
        'homeSensorConnected',       // ← camelCase (what Django currently returns)
        'home_sensor_connected',
        'sensor_connected',
        'home_sensor',
      ]),
    );
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is bool) return v;
    }
    return false;
  }
}
