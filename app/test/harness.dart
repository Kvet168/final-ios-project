import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show FontLoader, MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/core/data/providers.dart';
import 'package:wayfarer/core/network/api_client.dart';
import 'package:wayfarer/core/storage/token_store.dart';
import 'package:wayfarer/core/theme/theme.dart';
import 'package:wayfarer/core/widgets/image_catalog.dart';

/// Serves recorded API responses from test/fixtures so screens can be rendered (and screenshotted) offline.
class FakeApi extends ApiClient {
  FakeApi({this.overrides = const {}}) : super(TokenStore());
  final Map<String, Json> overrides;

  Json _file(String name) {
    final f = File('test/fixtures/$name.json');
    if (!f.existsSync()) throw ApiException('No fixture for $name', code: 'NETWORK');
    return jsonDecode(f.readAsStringSync()) as Json;
  }

  @override
  Future<Json> getJson(String path, {Json? query, cancel}) async {
    if (overrides.containsKey(path)) return overrides[path]!;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    switch (parts) {
      case ['home']:
        return _file('home');
      case ['meta']:
        return _file('meta');
      case ['ai', 'status']:
        return _file('ai_status');
      case ['destinations']:
        return _file('destinations');
      case ['destinations', final slug]:
        return _file('dest_$slug');
      case ['destinations', final slug, 'attractions']:
        return _file('dest_places_$slug');
      case ['accommodations']:
        return _file('stays');
      case ['accommodations', final slug]:
        return _file('stay_$slug');
      case ['accommodations', _, 'reviews']:
        return {'items': [], 'total': 0};
      case ['attractions']:
        return _file('attractions');
      case ['itineraries', _]:
        return _file('itinerary');
      case ['notifications']:
        return {'items': [], 'unread': 2};
      case ['wishlist']:
        return {'items': []};
    }
    throw ApiException('No fixture for $path', code: 'NETWORK');
  }

  @override
  Future<void> warmUp() async {}

  @override
  Future<Json> postJson(String path, {Object? body, Duration? timeout}) async {
    if (overrides.containsKey(path)) return overrides[path]!;
    if (path == '/ai/travel-plan') return _file('plan');
    if (path == '/ai/assistant') return _file('assistant');
    throw ApiException('No fixture for POST $path', code: 'NETWORK');
  }
}

/// Phone-sized surface (Pixel-class, 412x915 dp at 2.625x).
void phone(WidgetTester t, {double height = 915}) {
  t.view.devicePixelRatio = 2.625;
  t.view.physicalSize = Size(412 * 2.625, height * 2.625);
  addTearDown(t.view.reset);
}

Future<void> loadAssets() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ImageCatalog.load();
  // The test engine does not load pubspec fonts by itself; without these, text renders as blocks in screenshots.
  Future<void> font(String family, String path) async {
    final l = FontLoader(family)..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
    await l.load();
  }

  // flutter_map's tile cache asks path_provider for a directory.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => Directory.systemTemp.path);

  await font('Fraunces', 'assets/fonts/Fraunces.ttf');
  await font('PlusJakartaSans', 'assets/fonts/PlusJakartaSans.ttf');
  await font('MaterialIcons', 'C:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
}

/// Pumps a screen inside the real theme with fixture data, lets images decode, then settles animations.
Future<void> pumpScreen(WidgetTester t, Widget screen, {Map<String, Json> overrides = const {}, List<Override> extra = const []}) async {
  await t.pumpWidget(ProviderScope(
    overrides: [
      apiProvider.overrideWithValue(FakeApi(overrides: overrides)),
      onboardedProvider.overrideWith((ref) => OnboardedController(true)),
      ...extra,
    ],
    child: MaterialApp(theme: WayfarerTheme.light(), debugShowCheckedModeBanner: false, home: screen),
  ));
  await settle(t);
}

/// Real time must pass for image decoding; fake-async pumps alone never finish it.
Future<void> settle(WidgetTester t, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await t.pump(const Duration(milliseconds: 250));
  }
}
