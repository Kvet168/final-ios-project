// The launch screen covers the whole screen (it once shrank to its content and hugged the left edge), in English and Khmer.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayfarer/app/splash.dart';
import 'package:wayfarer/core/network/api_client.dart';
import 'package:wayfarer/core/theme/theme.dart';
import 'package:wayfarer/l10n/app_localizations.dart';

import 'harness.dart';

void main() {
  setUpAll(loadAssets);
  tearDown(() => Type.script = Script.latin);

  for (final lang in ['en', 'km']) {
    testWidgets('splash fills the screen ($lang)', (t) async {
      if (lang == 'km') Type.script = Script.khmer;
      phone(t);
      await t.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(FakeApi())],
          child: MaterialApp(
            theme: WayfarerTheme.light(),
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashGate(child: Scaffold(body: Text('home'))),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
      final screen = t.view.physicalSize / t.view.devicePixelRatio;
      final overlay = t.getSize(
        find
            .descendant(
              of: find.byType(SplashGate),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        overlay.width,
        screen.width,
        reason: 'splash must span the full width',
      );
      expect(
        overlay.height,
        screen.height,
        reason: 'splash must span the full height',
      );
      await t.pump(
        const Duration(seconds: 6),
      ); // let the timers and fade finish
    });
  }
}
