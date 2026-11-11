import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../config/env.dart';
import '../network/api_client.dart';
import '../network/live_socket.dart';
import '../../features/auth/auth_controller.dart';
import 'providers.dart';

/// Latest push from the server ({"type": "booking.status" | "notification", "data": {...}}); the shell shows it as a toast.
final liveEventProvider = StateProvider<Json?>((ref) => null);

/// Keeps one authenticated WebSocket open while a user is signed in and refreshes the screens that depend on the event.
final liveUpdatesProvider = Provider<void>((ref) {
  final userId = ref.watch(authProvider.select((a) => a.value?['id']));
  if (userId == null) return;
  final conn = _LiveConnection(ref)..start();
  ref.onDispose(conn.stop);
});

class _LiveConnection {
  _LiveConnection(this._ref);
  final Ref _ref;
  bool _stopped = false;
  StreamSubscription<String>? _sub;
  Timer? _retry;
  int _attempt = 0;

  void start() => unawaited(_connect());

  void stop() {
    _stopped = true;
    _retry?.cancel();
    _sub?.cancel();
  }

  Future<void> _connect() async {
    if (_stopped) return;
    try {
      var token = await _ref.read(tokenStoreProvider).access();
      if (token == null) return;
      var stream = await connectLive(Env.liveWsUrl, token);
      if (stream == null) {
        // Most likely an expired access token: a normal API call refreshes it, then try once more.
        await _ref.read(apiProvider).getJson('/users/me');
        token = await _ref.read(tokenStoreProvider).access();
        stream = token == null ? null : await connectLive(Env.liveWsUrl, token);
      }
      if (_stopped) return;
      if (stream == null) return _scheduleRetry();
      _attempt = 0;
      _sub = stream.listen(
        _onMessage,
        onDone: _scheduleRetry,
        onError: (_) => _scheduleRetry(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_stopped) return;
    _retry?.cancel();
    final secs = math.min(30, 1 << math.min(_attempt++, 5));
    _retry = Timer(Duration(seconds: secs), _connect);
  }

  void _onMessage(String raw) {
    if (_stopped) return;
    try {
      final msg = jsonDecode(raw) as Json;
      final type = msg['type'];
      final data = msg['data'];
      if (type == 'booking.status' && data is Map) {
        _ref.invalidate(bookingsProvider);
        final id = data['bookingId'];
        if (id is String) _ref.invalidate(bookingDetailProvider(id));
        _ref.invalidate(notificationsProvider);
      } else if (type == 'notification') {
        _ref.invalidate(notificationsProvider);
        _ref.read(liveEventProvider.notifier).state = msg;
      }
    } catch (_) {}
  }
}
