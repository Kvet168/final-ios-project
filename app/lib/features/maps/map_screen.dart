import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import 'place_map.dart';

/// Explore map: destinations, optionally stays near a chosen point (destination or the user's own location).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Position? me;
  String? permissionMsg;
  bool locating = false;
  Json? nearby;

  Future<void> _locate() async {
    setState(() {
      locating = true;
      permissionMsg = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => permissionMsg = 'Location services are turned off on this device.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        setState(() => permissionMsg = 'Location permission was declined. You can still explore the map and search by destination.');
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => permissionMsg = 'Location permission is blocked. Enable it in your device settings to use this feature.');
        return;
      }
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 12)));
      me = p;
      nearby = await ref.read(apiProvider).getJson('/accommodations', query: {'lat': p.latitude, 'lng': p.longitude, 'sort': 'distance', 'pageSize': 8, 'maxDistanceKm': 60});
      setState(() {});
    } catch (e) {
      setState(() => permissionMsg = 'We could not get your location (${e is ApiException ? e.message : 'timeout or unsupported'}).');
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = const DestQuery().copyWith(sort: 'popularity');
    final dests = ref.watch(destinationsProvider(q));
    final money = ref.watch(moneyProvider);
    final stays = (nearby?['items'] as List?)?.cast<Json>() ?? const [];
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: dests.when(
            loading: () => const SkeletonBox(height: double.infinity, radius: 0),
            error: (e, _) => SafeArea(child: ErrorState(error: e, onRetry: () => ref.invalidate(destinationsProvider(q)))),
            data: (r) {
              final items = (r['items'] as List).cast<Json>();
              return PlaceMap(
                height: MediaQuery.sizeOf(context).height,
                radius: 0,
                points: [
                  for (final d in items) MapPoint(lat: (d['lat'] as num).toDouble(), lng: (d['lng'] as num).toDouble(), title: d['name'] as String, subtitle: d['country'] as String?, kind: 'destination', onTap: () {}),
                  for (final s in stays) MapPoint(lat: (s['lat'] as num).toDouble(), lng: (s['lng'] as num).toDouble(), title: s['name'] as String, subtitle: '${money(s['price_from'] as num)} / night · ${s['distance_km']} km away', kind: 'stay'),
                  if (me != null) MapPoint(lat: me!.latitude, lng: me!.longitude, title: 'You are here', kind: 'user'),
                ],
              );
            },
          ),
        ),
        Positioned(top: top + 8, left: 12, child: GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onTap: () => context.canPop() ? context.pop() : context.go('/'))),
        Positioned(
          top: top + 8,
          right: 12,
          child: Pressable(
            onTap: locating ? null : _locate,
            radius: 99,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Tokens.primaryText, borderRadius: BorderRadius.circular(99), boxShadow: Tokens.softShadow(0.25)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                locating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text('Near me', style: Type.body(13.5, color: Colors.white, weight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
        if (permissionMsg != null)
          Positioned(
            left: 16,
            right: 16,
            top: top + 64,
            child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(18), boxShadow: Tokens.softShadow(0.2)), child: Text(permissionMsg!, style: Type.body(13, color: Tokens.warning, height: 1.45))),
          ),
        if (nearby != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + MediaQuery.paddingOf(context).bottom),
              decoration: const BoxDecoration(color: Tokens.pageBg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stays near you', style: Type.display(22)),
                const SizedBox(height: 10),
                if (stays.isEmpty)
                  Text('No stays within 60 km. Our listings cover specific destinations; explore one instead.', style: Type.body(13.5, color: Tokens.inkMuted))
                else
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: stays.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final s = stays[i];
                        return Pressable(
                          onTap: () => context.push('/stays/${s['slug']}'),
                          child: Container(
                            width: 250,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Tokens.border)),
                            child: Row(children: [
                              WImage(s['cover_image'] as String?, width: 66, height: 66, radius: 14, fallbackIcon: Icons.bed_outlined),
                              const SizedBox(width: 10),
                              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: Type.body(13.5, weight: FontWeight.w800)), Text('${s['distance_km']} km · ${money(s['price_from'] as num)}/night', style: Type.body(12, color: Tokens.inkMuted))])),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
              ]),
            ),
          ),
      ]),
    );
  }
}
