import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/splash.dart';
import 'core/data/providers.dart';
import 'core/theme/theme.dart';
import 'core/widgets/image_catalog.dart';
import 'features/auth/firebase_sign_in.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await ImageCatalog.load();
  await FirebaseSignIn.init(); // no-op until the Firebase settings are filled in (lib/core/config/firebase_config.dart)
  var onboarded = true;
  try {
    onboarded =
        (await SharedPreferences.getInstance()).getBool('onboarded') ?? false;
  } catch (_) {}
  final locale = await LocaleController.load();
  runApp(
    ProviderScope(
      overrides: [
        onboardedProvider.overrideWith((ref) => OnboardedController(onboarded)),
        localeProvider.overrideWith((ref) => LocaleController(locale)),
      ],
      child: const WayfarerApp(),
    ),
  );
}

class WayfarerApp extends ConsumerWidget {
  const WayfarerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(localeProvider);
    final device = View.of(context).platformDispatcher.locale;
    // Set before the theme is built so every text style picks up the right font and line height.
    final khmer = (chosen ?? device).languageCode == 'km';
    Type.script = khmer ? Script.khmer : Script.latin;
    Intl.defaultLocale = khmer
        ? 'km'
        : 'en'; // dates, times and numbers follow the app language
    return MaterialApp.router(
      title: 'WAYFARER',
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: WayfarerTheme.light(),
      routerConfig: ref.watch(routerProvider),
      locale: chosen,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Device set to any other language: English.
      localeResolutionCallback: (device, supported) => supported.firstWhere(
        (l) => l.languageCode == device?.languageCode,
        orElse: () => const Locale('en'),
      ),
      builder: (context, child) =>
          SplashGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
