// Every main screen laid out in Khmer (taller lines, MiSans Khmer) at a typical phone size, with no overflow.
// Overflow is reported as a FlutterError, which fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/core/data/providers.dart';
import 'package:wayfarer/core/theme/theme.dart';
import 'package:wayfarer/features/account/account_screens.dart';
import 'package:wayfarer/features/assistant/assistant_screen.dart';
import 'package:wayfarer/features/destinations/destinations_screen.dart';
import 'package:wayfarer/features/destinations/places_screen.dart';
import 'package:wayfarer/features/home/home_screen.dart';
import 'package:wayfarer/features/stays/stay_detail_screen.dart';
import 'package:wayfarer/features/stays/stays_screen.dart';
import 'package:wayfarer/features/trips/trips_screen.dart';

import 'harness.dart';

void main() {
  setUpAll(loadAssets);
  setUp(() => Type.script = Script.khmer);
  tearDown(() => Type.script = Script.latin);

  final screens = <String, Widget>{
    'home': const Scaffold(body: HomeScreen()),
    'destinations': const DestinationsScreen(),
    'destination detail': const DestinationDetailScreen(slug: 'siem-reap'),
    'places': const PlacesScreen(),
    'stays': const Scaffold(body: StaysScreen(initial: StayQuery())),
    'stay detail': const StayDetailScreen(
      slug: 'riverside-heritage-hotel',
      params: {},
    ),
    'trips': const Scaffold(body: TripsScreen()),
    'planner': const PlannerScreen(destination: 'kampot'),
    'itinerary': const ItineraryScreen(id: 'x'),
    'assistant': const AssistantScreen(),
    'account': const Scaffold(body: AccountScreen()),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name fits in Khmer', (t) async {
      phone(t);
      await pumpScreen(t, screen, locale: const Locale('km'));
      expect(t.takeException(), isNull);
    });
  }
}
