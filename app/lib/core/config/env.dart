/// Build-time configuration. Override with --dart-define=API_BASE_URL=https://host/api
class Env {
  /// The Spring Boot API. `localhost` works from the iOS Simulator; use http://10.0.2.2:8080/api from the Android emulator.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  /// WebSocket endpoint for live booking updates. Defaults to the API host's /ws.
  static const _wsOverride = String.fromEnvironment('LIVE_WS_URL');
  static String get liveWsUrl {
    if (_wsOverride.isNotEmpty) return _wsOverride;
    final u = Uri.parse(apiBaseUrl);
    return u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws', path: '/ws').toString();
  }

  static const mapsApiKey = String.fromEnvironment('MAPS_API_KEY');
  static const appName = 'WAYFARER';
}
