/// Browsers cannot set an Authorization header on a WebSocket upgrade, so live updates are mobile-only.
Future<Stream<String>?> connectLive(String url, String accessToken) async =>
    null;
