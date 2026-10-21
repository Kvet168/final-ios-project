import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/splash.dart';
import 'core/data/providers.dart';
import 'core/theme/theme.dart';
import 'core/widgets/image_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent, systemNavigationBarDividerColor: Colors.transparent));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await ImageCatalog.load();
  var onboarded = true;
  try {
    onboarded = (await SharedPreferences.getInstance()).getBool('onboarded') ?? false;
  } catch (_) {}
  runApp(ProviderScope(
    overrides: [onboardedProvider.overrideWith((ref) => OnboardedController(onboarded))],
    child: const WayfarerApp(),
  ));
}

class WayfarerApp extends ConsumerWidget {
  const WayfarerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'WAYFARER',
      debugShowCheckedModeBanner: false,
      theme: WayfarerTheme.light(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => SplashGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
