import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/api_client.dart';
import '../theme/theme.dart';
import 'save.dart';
import 'widgets.dart';

/// Portrait destination card: full-bleed photo, serif name and a budget chip.
class DestinationCard extends ConsumerWidget {
  const DestinationCard(
    this.d, {
    super.key,
    this.aspect = 0.8,
    this.heroTag,
    this.width,
    this.showSave = true,
  });
  final Json d;
  final double aspect;
  final String? heroTag;
  final double? width;
  final bool showSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final budget = d['daily_budget_usd'] as num?;
    final photo = WImage(
      d['cover_image'] as String?,
      label: 'Photo of ${d['name']}',
      width: double.infinity,
      height: double.infinity,
    );
    final card = AspectRatio(
      aspectRatio: aspect,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radius),
          boxShadow: Tokens.softShadow(0.12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              heroTag == null ? photo : Hero(tag: heroTag!, child: photo),
              const Scrim(top: true),
              if (showSave && d['id'] != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: SaveHeart(
                    kind: 'destination',
                    id: d['id'] as String,
                    size: 38,
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${d['country']}'.toUpperCase(),
                      style: Type.label(11, color: Tokens.onDarkMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['name'] as String,
                      style: Type.display(
                        24,
                        color: Colors.white,
                        height: 1.05,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (budget != null) ...[
                      const SizedBox(height: 10),
                      Glass(
                        radius: 99,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        child: Text(
                          context.l10n.fromPerDay(money(budget)),
                          style: Type.body(
                            11.5,
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Pressable(
      onTap: () => context.push('/destinations/${d['slug']}'),
      semanticLabel: '${d['name']}, ${d['country']}',
      child: width == null ? card : SizedBox(width: width, child: card),
    );
  }
}

/// Stay card. [compact] is the horizontal-carousel size; [grid] is the half-width card of a two-column list (it fills the
/// height it is given so neighbours line up, with the price pinned to the bottom).
class StayCard extends ConsumerWidget {
  const StayCard(
    this.s, {
    super.key,
    this.nights,
    this.query = const {},
    this.compact = false,
    this.grid = false,
    this.width,
    this.heroTag,
  });
  final Json s;
  final int? nights;
  final Map<String, String> query;
  final bool compact, grid;
  final double? width;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final price = (s['price_from'] ?? s['from_price_usd']) as num?;
    final total = s['total_for_stay_usd'] as num?;
    final dist = s['distance_km'] as num?;
    final l = context.l10n;
    final photo = WImage(
      s['cover_image'] as String?,
      label: l.photoFor('${s['name']}'),
      width: double.infinity,
      height: double.infinity,
      fallbackIcon: Icons.hotel_outlined,
    );
    final perks = <(IconData, String)>[
      if ((s['free_cancel_hours'] ?? 0) > 0)
        (Icons.event_available_outlined, l.perkFreeCancellation),
      if (s['breakfast_included'] == true)
        (Icons.free_breakfast_outlined, l.perkBreakfast),
      if (s['family_friendly'] == true)
        (Icons.family_restroom_outlined, l.perkFamily),
    ];

    final edge = grid ? 8.0 : 12.0;
    final media = AspectRatio(
      aspectRatio: grid ? 1.15 : (compact ? 1.35 : 1.5),
      child: Stack(
        fit: StackFit.expand,
        children: [
          heroTag == null ? photo : Hero(tag: heroTag!, child: photo),
          const Scrim(top: true, strength: 0.25),
          Positioned(
            left: edge,
            top: edge,
            child: Glass(
              radius: 99,
              tint: const Color(0x660F172A),
              padding: EdgeInsets.symmetric(
                horizontal: grid ? 8 : 10,
                vertical: grid ? 3 : 5,
              ),
              child: RatingBadge(
                rating: (s['rating_avg'] ?? 0) as num,
                count: (s['review_count'] ?? 0) as int,
                light: true,
              ),
            ),
          ),
          if (s['id'] != null)
            Positioned(
              right: grid ? 6 : 10,
              top: grid ? 6 : 10,
              child: SaveHeart(
                kind: 'accommodation',
                id: s['id'] as String,
                size: grid ? 32 : 38,
              ),
            ),
          if (s['is_demo'] == true)
            Positioned(
              left: edge,
              bottom: grid ? 8 : 10,
              child: const DemoBadge(onImage: true),
            ),
        ],
      ),
    );

    final suffix = total != null && nights != null && nights! > 0
        ? l.priceForNights(money(total), nights!)
        : l.perNight;
    final info = Padding(
      padding: grid
          ? const EdgeInsets.fromLTRB(12, 11, 12, 12)
          : const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: grid ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              if (s['stars'] != null) StarRow(s['stars'] as int, size: 13),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stayTypeLabel(l, s['type'] as String?).toUpperCase(),
                  style: Type.label(11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: grid ? 5 : 7),
          Text(
            s['name'] as String,
            style: Type.display(
              grid ? 16.5 : (compact ? 19 : 21),
              height: 1.12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: grid ? 4 : 5),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: Tokens.inkMuted,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${s['destination_name'] ?? ''}${dist != null ? '  ·  ${l.kmAway('$dist')}' : ''}',
                  style: Type.body(12.5, color: Tokens.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!compact && !grid && perks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final (i, l) in perks)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(i, size: 14, color: Tokens.primary),
                      const SizedBox(width: 4),
                      Text(
                        l,
                        style: Type.body(
                          11.5,
                          color: Tokens.inkSoft,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (grid) const Spacer() else const SizedBox(height: 12),
          if (price != null && grid) ...[
            const SizedBox(height: 8),
            Text(money(price), style: Type.display(19, height: 1)),
            const SizedBox(height: 3),
            Text(
              suffix,
              style: Type.body(12, color: Tokens.inkMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else if (price != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(price), style: Type.display(22, height: 1)),
                const SizedBox(width: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      suffix,
                      style: Type.body(12, color: Tokens.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Tokens.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    final card = Container(
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(grid ? 20 : Tokens.radius),
        boxShadow: Tokens.softShadow(0.08),
        border: Border.all(color: Tokens.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(grid ? 20 : Tokens.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: grid ? MainAxisSize.max : MainAxisSize.min,
          children: [
            media,
            grid ? Expanded(child: info) : info,
          ],
        ),
      ),
    );
    return Pressable(
      onTap: () => context.push(
        Uri(
          path: '/stays/${s['slug']}',
          queryParameters: query.isEmpty ? null : query,
        ).toString(),
      ),
      semanticLabel: l.stayCardSemantics(
        '${s['name']}',
        (s['stars'] ?? 0) as int,
        stayTypeLabel(l, s['type'] as String?),
      ),
      child: width == null ? card : SizedBox(width: width, child: card),
    );
  }
}

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
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: BorderRadius.circular(Tokens.radius),
          border: Border.all(color: Tokens.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 80,
                height: 80,
                child: p['image'] != null
                    ? WImage(
                        p['image'] as String?,
                        width: 80,
                        height: 80,
                        fallbackIcon: categoryIcon(cat),
                      )
                    : Container(
                        color: Tokens.neutralTint,
                        child: Icon(categoryIcon(cat), color: Tokens.primary),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] as String,
                    style: Type.body(15, weight: FontWeight.w700, height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(categoryIcon(cat), size: 14, color: Tokens.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          [
                            (cat ?? '').isEmpty
                                ? null
                                : categoryLabel(context.l10n, cat),
                            price == null
                                ? null
                                : (price == 0
                                      ? context.l10n.free
                                      : money(price)),
                            if (p['duration_min'] != null)
                              context.l10n.minutesShort(
                                p['duration_min'] as int,
                              ),
                          ].whereType<String>().join('  ·  '),
                          style: Type.body(12.5, color: Tokens.inkMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (p['is_demo'] == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: DemoBadge(),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Lays out children in one column on phones and more on wide screens.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTile = 280,
    this.spacing = 16,
  });
  final List<Widget> children;
  final double minTile;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cols = (c.maxWidth / minTile).floor().clamp(1, 4);
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}
