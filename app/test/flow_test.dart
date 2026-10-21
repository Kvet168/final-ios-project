// End-to-end navigation through the real router, shell, dock and screens (data from recorded fixtures).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/core/data/providers.dart';
import 'package:wayfarer/core/network/api_client.dart';
import 'package:wayfarer/main.dart';

import 'harness.dart';

void main() {
  setUpAll(loadAssets);

  Future<void> boot(WidgetTester t, {bool onboarded = true}) async {
    phone(t);
    await t.pumpWidget(ProviderScope(
      overrides: [apiProvider.overrideWithValue(FakeApi()), onboardedProvider.overrideWith((ref) => OnboardedController(onboarded))],
      child: const WayfarerApp(),
    ));
    await t.pump(const Duration(milliseconds: 2600));
    await settle(t, rounds: 4);
  }

  testWidgets('home -> stays tab -> assistant -> back', (t) async {
    await boot(t);
    expect(find.text('wander next?'), findsOneWidget);

    await t.tap(find.text('Stays').last);
    await settle(t, rounds: 4);
    expect(find.text('Find a place\nto rest'), findsOneWidget);

    await t.tap(find.bySemanticsLabel('Ask the AI travel guide'));
    await settle(t, rounds: 4);
    expect(find.text('Wayfarer Guide'), findsOneWidget);
    expect(find.text('Best time to go'), findsOneWidget);

    await t.tap(find.text('Best time to go'));
    await settle(t, rounds: 6);
    expect(find.textContaining('1 source'), findsOneWidget);
  });

  testWidgets('first launch shows the welcome carousel', (t) async {
    await boot(t, onboarded: false);
    expect(find.text('Southeast Asia,'), findsOneWidget);
    await t.tap(find.text('Next'));
    await settle(t, rounds: 3);
    await t.tap(find.text('Next'));
    await settle(t, rounds: 3);
    await t.tap(find.text('Start exploring'));
    await settle(t, rounds: 4);
    expect(find.text('wander next?'), findsOneWidget);
  });

  testWidgets('destination card opens the detail page', (t) async {
    await boot(t);
    await t.tap(find.textContaining('Siem Reap, Cambodia'));
    await settle(t, rounds: 6);
    expect(find.text('Find stays'), findsOneWidget);
  });
}
