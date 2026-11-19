/// Build-time configuration. Override with --dart-define=API_BASE_URL=https://host/api
class Env {
  /// The Spring Boot API, deployed on the VPS (Easypanel). For a local backend pass --dart-define=API_BASE_URL=http://localhost:8080/api
  /// (iOS Simulator) or http://10.0.2.2:8080/api (Android emulator).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://porseng-finalproject-api.b1exgs.easypanel.host/api',
  );

  /// WebSocket endpoint for live booking updates. Defaults to the API host's /ws.
  static const _wsOverride = String.fromEnvironment('LIVE_WS_URL');
  static String get liveWsUrl {
    if (_wsOverride.isNotEmpty) return _wsOverride;
    final u = Uri.parse(apiBaseUrl);
    return u
        .replace(scheme: u.scheme == 'https' ? 'wss' : 'ws', path: '/ws')
        .toString();
  }

  /// Turns a server-relative path such as /api/media/{id} into a full URL on the API host.
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final u = Uri.parse(apiBaseUrl);
    return u
        .replace(path: path, query: '')
        .toString()
        .replaceFirst(RegExp(r'\?$'), '');
  }

  static const mapsApiKey = String.fromEnvironment('MAPS_API_KEY');
  static const appName = 'Travel';
}
