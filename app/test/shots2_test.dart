import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/app/splash.dart';
import 'package:wayfarer/app/welcome.dart';
import 'package:wayfarer/features/account/account_screens.dart';
import 'package:wayfarer/features/assistant/assistant_screen.dart';
import 'package:wayfarer/features/maps/map_screen.dart';
import 'package:wayfarer/core/theme/theme.dart';
import 'package:wayfarer/features/trips/trips_screen.dart';

import 'harness.dart';

void main() {
  setUpAll(loadAssets);

  Future<void> shot(WidgetTester t, String name, Widget w, {double h = 915, Future<void> Function(WidgetTester)? act}) async {
    phone(t, height: h);
    await pumpScreen(t, w);
    if (act != null) await act(t);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
  }

  testWidgets('welcome', (t) => shot(t, 'welcome', const WelcomeScreen()));
  testWidgets('auth', (t) => shot(t, 'auth', const AuthScreen(register: false)));
  testWidgets('assistant empty', (t) => shot(t, 'assistant_empty', const AssistantScreen()));
  testWidgets('assistant answer', (t) => shot(t, 'assistant_answer', const AssistantScreen(initialQuestion: 'best time to visit Siem Reap'), h: 1100));
  testWidgets('trips', (t) => shot(t, 'trips', const Scaffold(body: TripsScreen()), h: 1300));
  testWidgets('planner', (t) => shot(t, 'planner', const PlannerScreen(destination: 'kampot')));
  testWidgets('itinerary', (t) => shot(t, 'itinerary', const ItineraryScreen(id: 'x'), h: 2200));
  testWidgets('account signed out', (t) => shot(t, 'account', const Scaffold(body: AccountScreen())));
  testWidgets('map', (t) => shot(t, 'map', const MapScreen()));
  testWidgets('typography: Inter for English, Kantumruy Pro for Khmer', (t) async {
    phone(t, height: 700);
    await t.pumpWidget(MaterialApp(
      theme: WayfarerTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Where will you wander next?', style: Type.display(34)),
            const SizedBox(height: 10),
            Text('ស្វាគមន៍មកកាន់ ព្រះរាជាណាចក្រកម្ពុជា', style: Type.display(30)),
            const SizedBox(height: 18),
            Text('Thirty destinations, hundreds of places and stays, from Angkor at sunrise to Kyoto in bloom.', style: Type.body(16, height: 1.5)),
            const SizedBox(height: 10),
            Text('ទីក្រុងភ្នំពេញ សៀមរាប កំពត និងកោះរ៉ុង ជាគោលដៅដ៏ពេញនិយម។ Siem Reap 2026 · \$55/day', style: Type.body(16, height: 1.6)),
            const SizedBox(height: 18),
            Text('TEMPLES · វត្តអារាម', style: Type.label(12)),
          ]),
        ),
      ),
    ));
    await settle(t, rounds: 2);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/typography.png'));
  });
  testWidgets('splash', (t) async {
    phone(t);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 200, height: 200, child: CustomPaint(painter: _P()))))));
  });
}

class _P extends CustomPainter {
  const _P();
  @override
  void paint(Canvas c, Size s) => CompassPainter(1).paint(c, s);
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
