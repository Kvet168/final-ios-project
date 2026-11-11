import 'dart:io';

/// Opens the authenticated WebSocket. Returns null when the server rejects the upgrade (expired token, 401).
Future<Stream<String>?> connectLive(String url, String accessToken) async {
  try {
    final ws = await WebSocket.connect(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 10));
    ws.pingInterval = const Duration(seconds: 25);
    return ws.where((m) => m is String).cast<String>();
  } on WebSocketException {
    return null;
  }
}
