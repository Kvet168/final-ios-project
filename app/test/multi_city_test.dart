// A trip through two cities: each day names its city, the second city opens with a transfer card, and the PDF follows suit.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/core/network/api_client.dart';
import 'package:wayfarer/core/theme/theme.dart';
import 'package:wayfarer/features/trips/trips_screen.dart';

import 'harness.dart';

Json _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Json;

/// The day chips: the page's horizontally scrolling list, which builds its children lazily.
Finder get chipList => find
    .byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    )
    .first;

Future<void> showChip(WidgetTester t, String label) async {
  for (var i = 0; i < 6 && find.text(label).evaluate().isEmpty; i++) {
    await t.drag(chipList, const Offset(-300, 0));
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadAssets);
  tearDown(() => Type.script = Script.latin);

  testWidgets('plan view labels days with their city and shows the transfer', (
    t,
  ) async {
    final plan = _fixture('plan_multi')['plan'] as Json;
    phone(t, height: 2400);
    await pumpScreen(
      t,
      Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PlanView(plan: plan),
          ),
        ),
      ),
    );
    expect(find.text('5 days in Kampot & Siem Reap'), findsOneWidget);
    expect(find.text('Day 1 · Kampot'), findsOneWidget);
    expect(planCityNames(plan), ['Kampot', 'Siem Reap']);

    await showChip(t, 'Day 4 · Siem Reap');
    expect(find.text('Day 4 · Siem Reap'), findsOneWidget);
    await t.tap(find.text('Day 4 · Siem Reap'));
    await settle(t, rounds: 3);
    expect(find.text('Transfer from Kampot'), findsOneWidget);
    expect(find.textContaining('km by road'), findsOneWidget);
    // Days that are not the arrival day have no transfer card.
    await t.drag(chipList, const Offset(900, 0));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Day 2 · Kampot'));
    await settle(t, rounds: 3);
    expect(find.text('Transfer from Kampot'), findsNothing);
    await t.pump(const Duration(seconds: 2)); // let entrance animations finish
  });

  testWidgets('a saved multi-city trip shows every city and exports a PDF', (
    t,
  ) async {
    Map? shared;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('net.nfet.printing'),
      (call) async {
        if (call.method == 'sharePdf') shared = call.arguments as Map;
        return 1;
      },
    );
    phone(t, height: 2600);
    await pumpScreen(
      t,
      const ItineraryScreen(id: 'x'),
      overrides: {'/itineraries/x': _fixture('itinerary_multi')},
    );
    expect(find.textContaining('KAMPOT · SIEM REAP'), findsOneWidget);
    await showChip(t, 'Day 5 · Siem Reap');
    expect(find.text('Day 5 · Siem Reap'), findsOneWidget);

    await t.tap(find.text('Save as PDF'));
    for (var i = 0; i < 400 && shared == null; i++) {
      await t.pump(const Duration(milliseconds: 50));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(
      shared,
      isNotNull,
      reason: 'the PDF was never handed to the share sheet',
    );
    final bytes = shared!['doc'] as Uint8List;
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final out = Platform.environment['PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  testWidgets('multi-city plan fits in Khmer', (t) async {
    Type.script = Script.khmer;
    final plan = _fixture('plan_multi')['plan'] as Json;
    phone(t, height: 2400);
    await pumpScreen(
      t,
      Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PlanView(plan: plan),
          ),
        ),
      ),
      locale: const Locale('km'),
    );
    await t.drag(chipList, const Offset(-600, 0));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.textContaining('Siem Reap').first);
    await settle(t, rounds: 3);
    expect(t.takeException(), isNull);
  });
}
