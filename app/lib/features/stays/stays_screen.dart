import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart';
import '../ads/ads.dart';
import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/widgets.dart';
import '../maps/place_map.dart';
import 'search_panel.dart';

class StaysScreen extends ConsumerStatefulWidget {
  const StaysScreen({super.key, required this.initial});
  final StayQuery initial;
  @override
  ConsumerState<StaysScreen> createState() => _StaysScreenState();
}

class _StaysScreenState extends ConsumerState<StaysScreen> {
  late StayQuery q = widget.initial;
  bool showMap = false;
  final _scroll = ScrollController();
  final List<Json> _items = [];
  int _total = 0, _page = 0, _pages = 1;
  int? _nights;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 700) {
        _more();
      }
    });
    _reload();
  }

  @override
  void dispose() {
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
        staySearchProvider(mine.copyWith(page: _page + 1)).future,
      );
      if (!mounted || mine != q) return;
      setState(() {
        _items.addAll((r['items'] as List).cast<Json>());
        _page = r['page'] as int;
        _pages = r['totalPages'] as int;
        _total = r['total'] as int;
        _nights = r['nights'] as int?;
        _error = null;
      });
    } catch (e) {
      if (mounted && mine == q) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _set(StayQuery n) {
    setState(() => q = n.copyWith(page: 1));
    _reload();
  }

  Future<void> _filters() async {
    await showModalBottomSheet<void>(
      useRootNavigator:
          true, // cover the bottom bar instead of sliding under it
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (c, sc) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _Filters(
                    q: q,
                    onChanged: (n) {
                      setState(() => q = n.copyWith(page: 1));
                      set(() {});
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16 + MediaQuery.paddingOf(c).bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(context.l10n.showResults),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final nights = nightsBetween(q.checkIn, q.checkOut);
    final urlQ = q.toUrlParams();
    final dests =
        (ref.watch(metaProvider).value?['destinations'] as List?) ?? const [];
    final destName = q.destination == null
        ? null
        : (dests
                      .cast<Map>()
                      .where((d) => d['slug'] == q.destination)
                      .firstOrNull?['name']
                  as String? ??
              q.destination);
    final where = destName ?? q.q ?? context.l10n.anywhere;
    final when = q.hasDates
        ? '${fmtDate(q.checkIn, pattern: 'd MMM')} – ${fmtDate(q.checkOut, pattern: 'd MMM')}'
        : context.l10n.anyDates;
    final who = context.l10n.guestsCount(q.adults + q.children);
    final active = _activeCount(q);

    return Scaffold(
      body: ToneOnScroll(
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 14,
                  20,
                  18,
                ),
                decoration: const BoxDecoration(
                  gradient: Tokens.dusk,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.staysEyebrowCaps,
                      style: Type.label(11, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.findPlaceToRest,
                      style: Type.display(
                        36,
                        color: Colors.white,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Pressable(
                      onTap: () => showSearchSheet(
                        context,
                        initial: q,
                        onSearch: (n) {
                          _set(
                            n.copyWith(
                              minPrice: q.minPrice,
                              maxPrice: q.maxPrice,
                              stars: q.stars,
                              amenities: q.amenities,
                              types: q.types,
                              sort: q.sort,
                              freeCancellation: q.freeCancellation,
                              breakfast: q.breakfast,
                              familyFriendly: q.familyFriendly,
                              minRating: q.minRating,
                            ),
                          );
                        },
                      ),
                      radius: 22,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Tokens.surface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Tokens.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    where,
                                    style: Type.body(
                                      15.5,
                                      weight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$when · $who · ${context.l10n.roomsCount(q.rooms)}',
                                    style: Type.body(
                                      12.5,
                                      color: Tokens.inkMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Tokens.inkMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Row(
                  children: [
                    WChip(
                      active > 0
                          ? context.l10n.filtersActive(active)
                          : context.l10n.filters,
                      icon: Icons.tune_rounded,
                      selected: active > 0,
                      onTap: _filters,
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: context.l10n.sort,
                      offset: const Offset(0, 48),
                      onSelected: (v) => _set(q.copyWith(sort: v)),
                      itemBuilder: (_) => [
                        for (final e in {
                          'relevance': context.l10n.sortRecommended,
                          'price_asc': context.l10n.sortPriceLow,
                          'price_desc': context.l10n.sortPriceHigh,
                          'rating': context.l10n.sortGuestRating,
                          if (q.lat != null)
                            'distance': context.l10n.sortDistance,
                        }.entries)
                          menuChoice(e.key, e.value, selected: q.sort == e.key),
                      ],
                      child: IgnorePointer(
                        child: WChip(
                          {
                                'relevance': context.l10n.sortRecommended,
                                'price_asc': context.l10n.sortPriceUp,
                                'price_desc': context.l10n.sortPriceDown,
                                'rating': context.l10n.topRated,
                                'distance': context.l10n.sortNearest,
                              }[q.sort] ??
                              context.l10n.sort,
                          icon: Icons.swap_vert_rounded,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Tokens.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Tokens.border),
                      ),
                      child: Row(
                        children: [
                          _toggle(
                            Icons.view_agenda_outlined,
                            !showMap,
                            () => setState(() => showMap = false),
                            context.l10n.listView,
                          ),
                          _toggle(
                            Icons.map_outlined,
                            showMap,
                            () => setState(() => showMap = true),
                            context.l10n.mapView,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SponsoredSearchBlock(q: q.q, destination: q.destination),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Text(
                  _items.isEmpty && _loading
                      ? context.l10n.searching
                      : '${context.l10n.staysCount(_total)} · ${q.hasDates ? context.l10n.totalsShownForNights(nights) : context.l10n.addDatesForAvailability}',
                  style: Type.body(
                    13,
                    color: Tokens.inkMuted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (_items.isEmpty && _loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (var i = 0; i < 3; i++)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: SkeletonBox(height: 250, radius: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: SkeletonBox(height: 250, radius: 20),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_items.isEmpty && !_loading && _error != null)
              SliverToBoxAdapter(
                child: ErrorState(error: _error!, onRetry: _reload),
              ),
            if (_items.isEmpty && !_loading && _error == null)
              SliverToBoxAdapter(
                child: EmptyState(
                  title: context.l10n.noStaysMatch,
                  message: q.hasDates
                      ? context.l10n.noStaysDatesHint
                      : context.l10n.noStaysHint,
                  action: OutlinedButton(
                    onPressed: () => _set(
                      StayQuery(
                        destination: q.destination,
                        checkIn: q.checkIn,
                        checkOut: q.checkOut,
                        adults: q.adults,
                        children: q.children,
                        rooms: q.rooms,
                      ),
                    ),
                    child: Text(context.l10n.clearFilters),
                  ),
                ),
              ),
            if (showMap && _items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PlaceMap(
                    height: MediaQuery.sizeOf(context).height * 0.55,
                    radius: 28,
                    points: [
                      for (final s in _items)
                        MapPoint(
                          lat: (s['lat'] as num).toDouble(),
                          lng: (s['lng'] as num).toDouble(),
                          title: s['name'] as String,
                          subtitle:
                              '${ref.read(moneyProvider)(s['price_from'] as num)} / night',
                          kind: 'stay',
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // Two hotels per row. IntrinsicHeight makes both cards in a row as tall as the taller one.
                sliver: SliverList.separated(
                  itemCount: (_items.length + 1) ~/ 2,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, row) {
                    final a = row * 2, b = a + 1;
                    return Reveal(
                      delay: Duration(milliseconds: 40 * (row % 3)),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StayCard(
                                _items[a],
                                nights: _nights,
                                query: urlQ,
                                grid: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: b < _items.length
                                  ? StayCard(
                                      _items[b],
                                      nights: _nights,
                                      query: urlQ,
                                      grid: true,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
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
            SliverToBoxAdapter(child: SizedBox(height: dockClearance(context))),
          ],
        ),
      ),
    );
  }

  Widget _toggle(IconData i, bool on, VoidCallback f, String label) =>
      Pressable(
        onTap: f,
        radius: 99,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: on ? Tokens.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Icon(i, size: 20, color: on ? Colors.white : Tokens.inkMuted),
        ),
      );
}

int _activeCount(StayQuery q) =>
    (q.minPrice != null ? 1 : 0) +
    (q.maxPrice != null ? 1 : 0) +
    q.stars.length +
    q.amenities.length +
    q.types.length +
    (q.freeCancellation ? 1 : 0) +
    (q.breakfast ? 1 : 0) +
    (q.familyFriendly ? 1 : 0) +
    (q.minRating != null ? 1 : 0);

class _Filters extends ConsumerWidget {
  const _Filters({required this.q, required this.onChanged});
  final StayQuery q;
  final ValueChanged<StayQuery> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(metaProvider).value;
    final amenities = ((meta?['amenities'] as List?) ?? const []).cast<Map>();
    final l = context.l10n;
    final types = {
      for (final t in const [
        'hotel',
        'guesthouse',
        'resort',
        'hostel',
        'boutique',
        'villa',
        'apartment',
      ])
        t: stayTypeLabel(l, t),
    };
    final money = ref.watch(moneyProvider);
    final range = RangeValues(q.minPrice ?? 0, q.maxPrice ?? 300);

    Widget group(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Type.body(15, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
    Widget sw(String label, bool v, ValueChanged<bool> f) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeThumbColor: Tokens.primary,
      title: Text(label, style: Type.body(14.5, weight: FontWeight.w600)),
      value: v,
      onChanged: f,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(l.filters, style: Type.display(28))),
            if (_activeCount(q) > 0)
              TextButton(
                onPressed: () => onChanged(
                  StayQuery(
                    destination: q.destination,
                    q: q.q,
                    checkIn: q.checkIn,
                    checkOut: q.checkOut,
                    adults: q.adults,
                    children: q.children,
                    rooms: q.rooms,
                    sort: q.sort,
                  ),
                ),
                child: Text(l.clearAll),
              ),
          ],
        ),
        const SizedBox(height: 16),
        group(
          l.pricePerNightRange(
            money(range.start),
            '${money(range.end)}${q.maxPrice == null ? '+' : ''}',
          ),
          RangeSlider(
            values: range,
            min: 0,
            max: 300,
            divisions: 30,
            activeColor: Tokens.primary,
            labels: RangeLabels(money(range.start), money(range.end)),
            onChanged: (v) => onChanged(
              q.copyWith(
                minPrice: v.start <= 0 ? null : v.start,
                maxPrice: v.end >= 300 ? null : v.end,
              ),
            ),
          ),
        ),
        group(
          l.starRating,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in [5, 4, 3, 2, 1])
                WChip(
                  '$s ★',
                  selected: q.stars.contains(s),
                  onTap: () => onChanged(
                    q.copyWith(
                      stars: q.stars.contains(s)
                          ? ({...q.stars}..remove(s))
                          : {...q.stars, s},
                    ),
                  ),
                ),
            ],
          ),
        ),
        group(
          l.guestRating,
          Wrap(
            spacing: 8,
            children: [
              for (final r in [4.5, 4.0, 3.5])
                WChip(
                  '$r+',
                  selected: q.minRating == r,
                  onTap: () => onChanged(
                    q.copyWith(minRating: q.minRating == r ? null : r),
                  ),
                ),
            ],
          ),
        ),
        group(
          l.propertyType,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in types.entries)
                WChip(
                  e.value,
                  selected: q.types.contains(e.key),
                  onTap: () => onChanged(
                    q.copyWith(
                      types: q.types.contains(e.key)
                          ? ({...q.types}..remove(e.key))
                          : {...q.types, e.key},
                    ),
                  ),
                ),
            ],
          ),
        ),
        group(
          l.popular,
          Column(
            children: [
              sw(
                l.perkFreeCancellation,
                q.freeCancellation,
                (v) => onChanged(q.copyWith(freeCancellation: v)),
              ),
              sw(
                l.breakfastAvailable,
                q.breakfast,
                (v) => onChanged(q.copyWith(breakfast: v)),
              ),
              sw(
                l.familyFriendly,
                q.familyFriendly,
                (v) => onChanged(q.copyWith(familyFriendly: v)),
              ),
            ],
          ),
        ),
        group(
          l.amenities,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in amenities)
                WChip(
                  amenityLabel(l, a['code'] as String?, a['label'] as String),
                  selected: q.amenities.contains(a['code']),
                  onTap: () => onChanged(
                    q.copyWith(
                      amenities: q.amenities.contains(a['code'])
                          ? ({...q.amenities}..remove(a['code']))
                          : {...q.amenities, a['code'] as String},
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
