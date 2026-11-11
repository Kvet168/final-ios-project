import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/widgets.dart';

/// Bottom sheet with full place details, hours (flagged indicative) and photo credit.
void showPlaceSheet(BuildContext context, WidgetRef ref, Json p) {
  final money = ref.read(moneyProvider);
  showModalBottomSheet<void>(
    useRootNavigator: true, // cover the bottom bar instead of sliding under it
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['image'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 210,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WImage(
                      p['image'] as String?,
                      full: true,
                      height: 210,
                      width: double.infinity,
                      label: context.l10n.photoOf('${p['name']}'),
                    ),
                    const Scrim(strength: 0.4),
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Pill(
                        categoryLabel(
                          context.l10n,
                          (p['category'] ?? p['kind']) as String?,
                        ),
                        icon: categoryIcon(p['category'] as String?),
                        color: Tokens.accent,
                        solid: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (p['image_credit'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  p['image_credit'] as String,
                  style: Type.body(12, color: Tokens.inkMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(p['name'] as String, style: Type.display(28)),
          if (p['destination_name'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${p['destination_name']}',
                style: Type.body(14, color: Tokens.inkMuted),
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p['price_usd'] != null)
                Pill(
                  (p['price_usd'] as num) == 0
                      ? 'Free entry'
                      : money(p['price_usd'] as num),
                  icon: Icons.payments_outlined,
                ),
              if (p['duration_min'] != null)
                Pill(
                  context.l10n.minutesShort(p['duration_min'] as int),
                  icon: Icons.schedule_rounded,
                ),
              if (p['opens_min'] != null)
                Pill(
                  '${fmtMinutes(p['opens_min'] as int)} – ${fmtMinutes((p['closes_min'] as int) % 1440)}${p['hours_verified'] == true ? '' : ' ${context.l10n.indicative}'}',
                  icon: Icons.access_time_rounded,
                  color: Tokens.primary,
                ),
              if (p['family_friendly'] == true)
                Pill(
                  context.l10n.familyFriendly,
                  icon: Icons.family_restroom_outlined,
                  color: Tokens.primary,
                ),
              if (p['is_demo'] == true) const DemoBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            p['description'] as String,
            style: Type.body(15.5, height: 1.6, color: Tokens.inkSoft),
          ),
          if (p['tips'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                p['tips'] as String,
                style: Type.body(12.5, color: Tokens.inkMuted, height: 1.5),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (p['lat'] != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${p['lat']},${p['lng']}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(context.l10n.directions),
                  ),
                ),
              if (p['lat'] != null && p['destination_slug'] != null)
                const SizedBox(width: 10),
              if (p['destination_slug'] != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(c);
                      context.push('/destinations/${p['destination_slug']}');
                    },
                    icon: const Icon(Icons.public_rounded),
                    label: Text(context.l10n.destination),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key, this.category, this.kind});
  final String? category, kind;
  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  late PlaceQuery q = PlaceQuery(category: widget.category, kind: widget.kind);
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final List<Json> _items = [];
  int _total = 0, _page = 0, _pages = 1;
  bool _loading = false;
  Object? _error;
  static const cats = [
    'temple',
    'museum',
    'landmark',
    'market',
    'nature',
    'beach',
    'culture',
    'tour',
    'outdoor',
    'family',
    'cafe',
    'food',
    'history',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
        _more();
      }
    });
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reload() {
    _items.clear();
    _page = 0;
    _pages = 1;
    _total = 0;
    _error = null;
    _more();
  }

  Future<void> _more() async {
    if (_loading || _page >= _pages) return;
    setState(() => _loading = true);
    final mine = q;
    try {
      final r = await ref.read(
        placesProvider(mine.copyWith(page: _page + 1)).future,
      );
      if (!mounted || mine != q) return;
      setState(() {
        _items.addAll((r['items'] as List).cast<Json>());
        _page = r['page'] as int;
        _pages = r['totalPages'] as int;
        _total = r['total'] as int;
        _error = null;
      });
    } catch (e) {
      if (mounted && mine == q) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _set(PlaceQuery n) {
    setState(() => q = n);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Tokens.pageBg,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 14,
              ),
              title: Text(context.l10n.placesTitle, style: Type.display(26)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.searchPlacesHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: q.q == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            _set(q.copyWith(q: null));
                          },
                        ),
                ),
                onSubmitted: (v) => _set(
                  q.copyWith(q: v.trim().isEmpty ? null : v.trim(), page: 1),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final (label, v) in [
                    (context.l10n.kindAttractions, 'attraction'),
                    (context.l10n.kindActivities, 'activity'),
                    (context.l10n.kindRestaurants, 'restaurant'),
                  ]) ...[
                    WChip(
                      label,
                      selected: q.kind == v,
                      onTap: () => _set(
                        q.copyWith(kind: q.kind == v ? null : v, page: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 6,
                    ),
                    color: Tokens.border,
                  ),
                  for (final c in cats) ...[
                    WChip(
                      categoryLabel(context.l10n, c),
                      icon: categoryIcon(c),
                      selected: q.category == c,
                      onTap: () => _set(
                        q.copyWith(
                          category: q.category == c ? null : c,
                          page: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          if (_items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  context.l10n.placesCount(_total),
                  style: Type.body(
                    13,
                    color: Tokens.inkMuted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (_items.isEmpty && _loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SkeletonList(count: 6, itemHeight: 100),
              ),
            ),
          if (_items.isEmpty && !_loading && _error != null)
            SliverToBoxAdapter(
              child: ErrorState(error: _error!, onRetry: _reload),
            ),
          if (_items.isEmpty && !_loading && _error == null)
            SliverToBoxAdapter(
              child: EmptyState(
                title: context.l10n.noPlacesMatch,
                message: context.l10n.noPlacesHint,
                action: OutlinedButton(
                  onPressed: () {
                    _search.clear();
                    _set(const PlaceQuery());
                  },
                  child: Text(context.l10n.clearFilters),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final it = _items[i];
                return PlaceTile(
                  it,
                  onTap: () => showPlaceSheet(context, ref, it),
                  trailing: it['destination_name'] == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: SizedBox(
                            width: 70,
                            child: Text(
                              it['destination_name'] as String,
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              style: Type.body(12, color: Tokens.inkMuted),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          if (_loading && _items.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: 40 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}
