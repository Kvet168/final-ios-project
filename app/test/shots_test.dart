// Screenshot tests: `flutter test test/shots_test.dart --update-goldens` writes PNGs to test/shots/.
// They double as a visual regression record of the real UI rendered with bundled photos and recorded API data.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/features/destinations/destinations_screen.dart';
import 'package:wayfarer/features/destinations/places_screen.dart';
import 'package:wayfarer/core/data/providers.dart';
import 'package:wayfarer/features/home/home_screen.dart';
import 'package:wayfarer/features/stays/stay_detail_screen.dart';
import 'package:wayfarer/features/stays/stays_screen.dart';

import 'harness.dart';

void main() {
  setUpAll(loadAssets);

  Future<void> shot(
    WidgetTester t,
    String name,
    Widget w, {
    double h = 915,
    Future<void> Function(WidgetTester)? act,
  }) async {
    phone(t, height: h);
    await pumpScreen(t, w);
    if (act != null) await act(t);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets(
    'home',
    (t) => shot(t, 'home', const Scaffold(body: HomeScreen()), h: 2300),
  );
  testWidgets(
    'destinations',
    (t) => shot(t, 'destinations', const DestinationsScreen()),
  );
  testWidgets(
    'destination detail',
    (t) => shot(
      t,
      'destination_detail',
      const DestinationDetailScreen(slug: 'siem-reap'),
      h: 2600,
    ),
  );
  testWidgets('places', (t) => shot(t, 'places', const PlacesScreen()));
  testWidgets(
    'stays',
    (t) => shot(
      t,
      'stays',
      const Scaffold(body: StaysScreen(initial: StayQuery())),
      h: 1700,
    ),
  );
  testWidgets(
    'stays sort menu',
    (t) => shot(
      t,
      'stays_sort_menu',
      const Scaffold(body: StaysScreen(initial: StayQuery())),
      h: 900,
      act: (t) async {
        await t.tap(find.text('Recommended'));
        await settle(t, rounds: 3);
      },
    ),
  );
  testWidgets(
    'stay detail',
    (t) => shot(
      t,
      'stay_detail',
      const StayDetailScreen(slug: 'riverside-heritage-hotel', params: {}),
      h: 3200,
    ),
  );
}
