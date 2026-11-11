import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

class MapPoint {
  const MapPoint({
    required this.lat,
    required this.lng,
    required this.title,
    this.subtitle,
    this.kind = 'place',
    this.index,
    this.onTap,
  });
  final double lat, lng;
  final String title;
  final String? subtitle;
  final String kind; // destination | stay | place | restaurant | user
  final int? index;
  final VoidCallback? onTap;
  LatLng get ll => LatLng(lat, lng);
}

Color _kindColor(String k) => switch (k) {
  'stay' => Tokens.accent,
  'destination' => Tokens.primaryText,
  'restaurant' => Tokens.accentDeep,
  'user' => Tokens.primary,
  _ => Tokens.primary,
};

IconData _kindIcon(String k) => switch (k) {
  'stay' => Icons.bed_rounded,
  'restaurant' => Icons.restaurant_rounded,
  'destination' => Icons.location_city_rounded,
  'user' => Icons.my_location_rounded,
  _ => Icons.place_rounded,
};

/// Map on OpenStreetMap tiles (no API key), markers and an optional route.
/// The dashed line joins stops in order; it is a straight connection, not a routed road path.
class PlaceMap extends StatefulWidget {
  const PlaceMap({
    super.key,
    required this.points,
    this.height = 320,
    this.drawRoute = false,
    this.interactive = true,
    this.showDetail = true,
    this.radius = Tokens.radius,
  });
  final List<MapPoint> points;
  final double height, radius;
  final bool drawRoute;
  final bool interactive;
  final bool showDetail;

  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap> {
  MapPoint? selected;
  final controller = MapController();

  @override
  Widget build(BuildContext context) {
    final pts = widget.points;
    if (pts.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text(context.l10n.noLocations)),
      );
    }
    final bounds = LatLngBounds.fromPoints(pts.map((p) => p.ll).toList());
    final single =
        pts.length == 1 ||
        (bounds.north == bounds.south && bounds.east == bounds.west);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: single ? pts.first.ll : bounds.center,
                initialZoom: single ? 14 : 12,
                initialCameraFit: single
                    ? null
                    : CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(56),
                        maxZoom: 16,
                      ),
                interactionOptions: InteractionOptions(
                  flags: widget.interactive
                      ? InteractiveFlag.all & ~InteractiveFlag.rotate
                      : InteractiveFlag.none,
                ),
                onTap: (_, _) => setState(() => selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.wayfarer.wayfarer',
                ),
                if (widget.drawRoute && pts.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: pts.map((p) => p.ll).toList(),
                        strokeWidth: 4,
                        color: Tokens.primary.withValues(alpha: 0.8),
                        pattern: StrokePattern.dashed(segments: const [9, 7]),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final p in pts)
                      Marker(
                        point: p.ll,
                        width: 44,
                        height: 44,
                        child: Semantics(
                          button: true,
                          label: p.title,
                          child: GestureDetector(
                            onTap: () {
                              tick();
                              setState(() => selected = p);
                              p.onTap?.call();
                            },
                            child: AnimatedScale(
                              scale: selected == p ? 1.2 : 1,
                              duration: const Duration(milliseconds: 180),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _kindColor(p.kind),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                      color: Color(0x40000000),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: p.index != null
                                      ? Text(
                                          '${p.index}',
                                          style: Type.body(
                                            14,
                                            color: Colors.white,
                                            weight: FontWeight.w800,
                                          ),
                                        )
                                      : Icon(
                                          _kindIcon(p.kind),
                                          color: Colors.white,
                                          size: 21,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.showDetail && selected != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 28,
                child: Reveal(
                  dy: 10,
                  duration: const Duration(milliseconds: 260),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    decoration: BoxDecoration(
                      color: Tokens.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: Tokens.softShadow(0.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _kindColor(selected!.kind)
                                .withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _kindIcon(selected!.kind),
                            color: _kindColor(selected!.kind),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Type.body(15, weight: FontWeight.w800),
                              ),
                              if (selected!.subtitle != null)
                                Text(
                                  selected!.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Type.body(
                                    12.5,
                                    color: Tokens.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: context.l10n.directionsInMaps,
                          icon: const Icon(Icons.directions_rounded),
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${selected!.lat},${selected!.lng}',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
