import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/api_client.dart';
import '../theme/theme.dart';
import 'save.dart';
import 'widgets.dart';

/// Portrait destination card: full-bleed photo, serif name and a budget chip.
class DestinationCard extends ConsumerWidget {
  const DestinationCard(this.d, {super.key, this.aspect = 0.8, this.heroTag, this.width, this.showSave = true});
  final Json d;
  final double aspect;
  final String? heroTag;
  final double? width;
  final bool showSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final budget = d['daily_budget_usd'] as num?;
    final photo = WImage(d['cover_image'] as String?, label: 'Photo of ${d['name']}', width: double.infinity, height: double.infinity);
    final card = AspectRatio(
      aspectRatio: aspect,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Tokens.radius), boxShadow: Tokens.softShadow(0.12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radius),
          child: Stack(fit: StackFit.expand, children: [
            heroTag == null ? photo : Hero(tag: heroTag!, child: photo),
            const Scrim(top: true),
            if (showSave && d['id'] != null) Positioned(top: 10, right: 10, child: SaveHeart(kind: 'destination', id: d['id'] as String, size: 38)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('${d['country']}'.toUpperCase(), style: Type.label(10.5, color: Tokens.onDarkMuted)),
                const SizedBox(height: 4),
                Text(d['name'] as String, style: Type.display(24, color: Colors.white, height: 1.05), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (budget != null) ...[
                  const SizedBox(height: 10),
                  Glass(radius: 99, padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5), child: Text('from ${money(budget)} / day', style: Type.body(11.5, color: Colors.white, weight: FontWeight.w700))),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
    return Pressable(onTap: () => context.push('/destinations/${d['slug']}'), semanticLabel: '${d['name']}, ${d['country']}', child: width == null ? card : SizedBox(width: width, child: card));
  }
}

/// Stay card. [compact] is the horizontal-carousel size.
class StayCard extends ConsumerWidget {
  const StayCard(this.s, {super.key, this.nights, this.query = const {}, this.compact = false, this.width, this.heroTag});
  final Json s;
  final int? nights;
  final Map<String, String> query;
  final bool compact;
  final double? width;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final price = (s['price_from'] ?? s['from_price_usd']) as num?;
    final total = s['total_for_stay_usd'] as num?;
    final dist = s['distance_km'] as num?;
    final photo = WImage(s['cover_image'] as String?, label: 'Photo for ${s['name']}', width: double.infinity, height: double.infinity, fallbackIcon: Icons.hotel_outlined);
    final perks = <(IconData, String)>[
      if ((s['free_cancel_hours'] ?? 0) > 0) (Icons.event_available_outlined, 'Free cancellation'),
      if (s['breakfast_included'] == true) (Icons.free_breakfast_outlined, 'Breakfast'),
      if (s['family_friendly'] == true) (Icons.family_restroom_outlined, 'Family'),
    ];

    final media = AspectRatio(
      aspectRatio: compact ? 1.35 : 1.5,
      child: Stack(fit: StackFit.expand, children: [
        heroTag == null ? photo : Hero(tag: heroTag!, child: photo),
        const Scrim(top: true, strength: 0.25),
        Positioned(left: 12, top: 12, child: Glass(radius: 99, tint: const Color(0x660F172A), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: RatingBadge(rating: (s['rating_avg'] ?? 0) as num, count: (s['review_count'] ?? 0) as int, light: true))),
        if (s['id'] != null) Positioned(right: 10, top: 10, child: SaveHeart(kind: 'accommodation', id: s['id'] as String, size: 38)),
        if (s['is_demo'] == true) const Positioned(left: 12, bottom: 10, child: DemoBadge(onImage: true)),
      ]),
    );

    final info = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          if (s['stars'] != null) StarRow(s['stars'] as int, size: 13),
          const SizedBox(width: 8),
          Flexible(child: Text(_typeLabel(s['type'] as String?).toUpperCase(), style: Type.label(10.5), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 7),
        Text(s['name'] as String, style: Type.display(compact ? 19 : 21, height: 1.12), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 5),
        Row(children: [
          const Icon(Icons.place_outlined, size: 14, color: Tokens.inkMuted),
          const SizedBox(width: 3),
          Expanded(child: Text('${s['destination_name'] ?? ''}${dist != null ? '  ·  $dist km away' : ''}', style: Type.body(12.5, color: Tokens.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        if (!compact && perks.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 4, children: [
            for (final (i, l) in perks) Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 14, color: Tokens.primary), const SizedBox(width: 4), Text(l, style: Type.body(11.5, color: Tokens.inkSoft, weight: FontWeight.w600))]),
          ]),
        ],
        const SizedBox(height: 12),
        if (price != null)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(price), style: Type.display(22, height: 1)),
            const SizedBox(width: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(total != null && nights != null && nights! > 0 ? '${money(total)} for $nights night${nights == 1 ? '' : 's'}' : '/ night', style: Type.body(12, color: Tokens.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Tokens.primary, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_outward_rounded, size: 18, color: Colors.white),
            ),
          ]),
      ]),
    );

    final card = Container(
      decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(Tokens.radius), boxShadow: Tokens.softShadow(0.08), border: Border.all(color: Tokens.border)),
      child: ClipRRect(borderRadius: BorderRadius.circular(Tokens.radius), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [media, info])),
    );
    return Pressable(
      onTap: () => context.push(Uri(path: '/stays/${s['slug']}', queryParameters: query.isEmpty ? null : query).toString()),
      semanticLabel: '${s['name']}, ${s['stars']} star ${s['type']}',
      child: width == null ? card : SizedBox(width: width, child: card),
    );
  }
}

String _typeLabel(String? t) => switch (t) {
      'hotel' => 'Hotel',
      'guesthouse' => 'Guesthouse',
      'resort' => 'Resort',
      'hostel' => 'Hostel',
      'boutique' => 'Boutique hotel',
      'villa' => 'Villa',
      'apartment' => 'Apartment',
      _ => t ?? '',
    };

String typeLabel(String? t) => _typeLabel(t);

IconData categoryIcon(String? c) => switch (c) {
      'temple' => Icons.temple_buddhist_outlined,
      'museum' => Icons.museum_outlined,
      'market' => Icons.storefront_outlined,
      'nature' => Icons.forest_outlined,
      'beach' => Icons.beach_access_outlined,
      'food' => Icons.restaurant_outlined,
      'cafe' => Icons.local_cafe_outlined,
      'culture' => Icons.theater_comedy_outlined,
      'tour' => Icons.directions_boat_outlined,
      'outdoor' => Icons.hiking_outlined,
      'family' => Icons.family_restroom_outlined,
      'landmark' => Icons.account_balance_outlined,
      'history' => Icons.history_edu_outlined,
      _ => Icons.place_outlined,
    };

class PlaceTile extends ConsumerWidget {
  const PlaceTile(this.p, {super.key, this.trailing, this.onTap});
  final Json p;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final price = p['price_usd'] as num?;
    final cat = p['category'] as String?;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(Tokens.radius), border: Border.all(color: Tokens.border)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 80,
              height: 80,
              child: p['image'] != null ? WImage(p['image'] as String?, width: 80, height: 80, fallbackIcon: categoryIcon(cat)) : Container(color: Tokens.neutralTint, child: Icon(categoryIcon(cat), color: Tokens.primary)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] as String, style: Type.body(15, weight: FontWeight.w700, height: 1.25), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                Icon(categoryIcon(cat), size: 14, color: Tokens.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    [
                      (cat ?? '').isEmpty ? null : capitalize(cat!),
                      price == null ? null : (price == 0 ? 'Free' : money(price)),
                      if (p['duration_min'] != null) '${p['duration_min']} min',
                    ].whereType<String>().join('  ·  '),
                    style: Type.body(12.5, color: Tokens.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              if (p['is_demo'] == true) const Padding(padding: EdgeInsets.only(top: 6), child: DemoBadge()),
            ]),
          ),
          ?trailing,
        ]),
      ),
    );
  }
}

/// Lays out children in one column on phones and more on wide screens.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minTile = 280, this.spacing = 16});
  final List<Widget> children;
  final double minTile;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = (c.maxWidth / minTile).floor().clamp(1, 4);
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(spacing: spacing, runSpacing: spacing, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
      });
}
