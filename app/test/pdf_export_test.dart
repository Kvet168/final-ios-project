// "Save as PDF" on a saved itinerary produces a real multi-page PDF and hands it to the share sheet.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/features/trips/trips_screen.dart';

import 'harness.dart';

void main() {
  setUpAll(loadAssets);

  testWidgets('itinerary exports a PDF through the share sheet', (t) async {
    Map? shared;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('net.nfet.printing'),
      (call) async {
        if (call.method == 'sharePdf') shared = call.arguments as Map;
        return 1;
      },
    );
    phone(t, height: 2200);
    await pumpScreen(t, const ItineraryScreen(id: 'x'));

    await t.tap(find.text('Save as PDF'));
    // The export waits for frames and timers (advanced by pump) and encodes images (real async work), so alternate.
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
    expect((shared!['name'] as String).endsWith('.pdf'), isTrue);
    // Cover plus one section per day: several pages, each with a photo-quality image.
    final pages = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(bytes))
        .length;
    expect(pages, greaterThanOrEqualTo(2));
    final out = Platform.environment['PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
