import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/providers.dart';
import '../core/widgets/widgets.dart';
import '../features/account/account_screens.dart';
import '../features/admin/admin_screens.dart';
import '../features/assistant/assistant_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/bookings/bookings_screen.dart';
import '../features/bookings/checkout_screen.dart';
import '../features/destinations/destinations_screen.dart';
import '../features/destinations/places_screen.dart';
import '../features/home/home_screen.dart';
import '../features/maps/map_screen.dart';
import '../features/stays/stay_detail_screen.dart';
import '../features/stays/stays_screen.dart';
import '../features/trips/trips_screen.dart';
import 'shell.dart';
import 'welcome.dart';

const _protectedPrefixes = ['/bookings', '/book/', '/wishlist', '/notifications', '/admin', '/partner'];

class _Refresh extends ChangeNotifier {
  _Refresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(onboardedProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _Refresh(ref);
  final rootKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();

  GoRoute push(String path, Widget Function(GoRouterState s) build, {bool rise = false}) => GoRoute(
        path: path,
        parentNavigatorKey: rootKey,
        pageBuilder: (_, s) => rise ? _rise(s, build(s)) : _slide(s, build(s)),
      );

  return GoRouter(
    navigatorKey: rootKey,
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!ref.read(onboardedProvider) && path != '/welcome') return '/welcome';
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;
      if (_protectedPrefixes.any(path.startsWith) && !auth.signedIn) {
        return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
      }
      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (_, s) => _fade(s, const HomeScreen())),
          GoRoute(path: '/stays', pageBuilder: (_, s) => _fade(s, StaysScreen(key: ValueKey(s.uri.toString()), initial: StayQuery.fromUrl(s.uri.queryParameters)))),
          GoRoute(path: '/trips', pageBuilder: (_, s) => _fade(s, const TripsScreen())),
          GoRoute(path: '/account', pageBuilder: (_, s) => _fade(s, const AccountScreen())),
        ],
      ),
      GoRoute(path: '/welcome', parentNavigatorKey: rootKey, pageBuilder: (_, s) => _fade(s, const WelcomeScreen())),
      push('/destinations', (s) => DestinationsScreen(key: ValueKey(s.uri.toString()), initialTag: s.uri.queryParameters['tag'])),
      push('/destinations/:slug', (s) => DestinationDetailScreen(key: ValueKey(s.pathParameters['slug']), slug: s.pathParameters['slug']!)),
      push('/places', (s) => PlacesScreen(key: ValueKey(s.uri.toString()), category: s.uri.queryParameters['category'], kind: s.uri.queryParameters['kind'])),
      push('/stays/:slug', (s) => StayDetailScreen(key: ValueKey(s.uri.toString()), slug: s.pathParameters['slug']!, params: s.uri.queryParameters)),
      push('/book/:roomTypeId', (s) => CheckoutScreen(key: ValueKey(s.uri.toString()), roomTypeId: s.pathParameters['roomTypeId']!, params: s.uri.queryParameters)),
      push('/bookings', (s) => const BookingsScreen()),
      push('/bookings/:id', (s) => BookingDetailScreen(key: ValueKey(s.pathParameters['id']), id: s.pathParameters['id']!, justPaid: s.uri.queryParameters['paid'] == '1')),
      push('/trips/new', (s) => PlannerScreen(key: ValueKey(s.uri.toString()), destination: s.uri.queryParameters['destination'])),
      push('/trips/:id', (s) => ItineraryScreen(key: ValueKey(s.pathParameters['id']), id: s.pathParameters['id']!)),
      push('/assistant', (s) => AssistantScreen(key: ValueKey(s.uri.toString()), initialQuestion: s.uri.queryParameters['q'], destination: s.uri.queryParameters['destination']), rise: true),
      push('/map', (s) => const MapScreen()),
      push('/login', (s) => AuthScreen(register: false, next: s.uri.queryParameters['next']), rise: true),
      push('/register', (s) => AuthScreen(register: true, next: s.uri.queryParameters['next']), rise: true),
      push('/wishlist', (s) => const WishlistScreen()),
      push('/notifications', (s) => const NotificationsScreen()),
      push('/admin', (s) => Scaffold(appBar: AppBar(title: const Text('Administration')), body: const SafeArea(child: AdminScreen()))),
      push('/partner', (s) => Scaffold(appBar: AppBar(title: const Text('Partner portal')), body: const SafeArea(child: PartnerScreen()))),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.explore_off_outlined,
          title: 'We could not find that page',
          message: state.uri.toString(),
          action: FilledButton(onPressed: () => context.go('/'), child: const Text('Back to Discover')),
        ),
      ),
    ),
  );
});

Page<void> _fade(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: ValueKey(s.uri.toString()),
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, _, c) => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: c),
    );

/// Detail pages glide in from the right and the page beneath eases away.
Page<void> _slide(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondary, c) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return SlideTransition(
          position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(position: Tween(begin: Offset.zero, end: const Offset(-0.06, 0)).animate(CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic)), child: c),
          ),
        );
      },
    );

/// Full-screen tasks (assistant, sign-in) rise from the bottom like a sheet.
Page<void> _rise(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, _, c) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
        return SlideTransition(position: Tween(begin: const Offset(0, 0.14), end: Offset.zero).animate(curved), child: FadeTransition(opacity: curved, child: c));
      },
    );
