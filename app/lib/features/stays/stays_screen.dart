import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart';
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
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 700) _more();
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
      final r = await ref.read(staySearchProvider(mine.copyWith(page: _page + 1)).future);
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
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (c, sc) => Column(children: [
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _Filters(q: q, onChanged: (n) {
                  setState(() => q = n.copyWith(page: 1));
                  set(() {});
                }),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + MediaQuery.paddingOf(c).bottom),
              child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Show results'))),
            ),
          ]),
        ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final nights = nightsBetween(q.checkIn, q.checkOut);
    final urlQ = q.toUrlParams();
    final dests = (ref.watch(metaProvider).value?['destinations'] as List?) ?? const [];
    final destName = q.destination == null ? null : (dests.cast<Map>().where((d) => d['slug'] == q.destination).firstOrNull?['name'] as String? ?? q.destination);
    final where = destName ?? q.q ?? 'Anywhere';
    final when = q.hasDates ? '${fmtDate(q.checkIn, pattern: 'd MMM')} – ${fmtDate(q.checkOut, pattern: 'd MMM')}' : 'Any dates';
    final who = '${q.adults + q.children} guest${q.adults + q.children > 1 ? 's' : ''}';
    final active = _activeCount(q);

    return Scaffold(
      body: ToneOnScroll(child: CustomScrollView(controller: _scroll, physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 20, 18),
            decoration: const BoxDecoration(gradient: Tokens.dusk, borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STAYS', style: Type.label(11, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Find a place\nto rest', style: Type.display(36, color: Colors.white, height: 1.02)),
              const SizedBox(height: 18),
              Pressable(
                onTap: () => showSearchSheet(context, initial: q, onSearch: (n) {
                  _set(n.copyWith(minPrice: q.minPrice, maxPrice: q.maxPrice, stars: q.stars, amenities: q.amenities, types: q.types, sort: q.sort, freeCancellation: q.freeCancellation, breakfast: q.breakfast, familyFriendly: q.familyFriendly, minRating: q.minRating));
                }),
                radius: 22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(22)),
                  child: Row(children: [
                    const Icon(Icons.search_rounded, color: Tokens.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(where, style: Type.body(15.5, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('$when · $who · ${q.rooms} room${q.rooms > 1 ? 's' : ''}', style: Type.body(12.5, color: Tokens.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    const Icon(Icons.edit_outlined, size: 20, color: Tokens.inkMuted),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(children: [
              WChip(active > 0 ? 'Filters · $active' : 'Filters', icon: Icons.tune_rounded, selected: active > 0, onTap: _filters),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Sort',
                onSelected: (v) => _set(q.copyWith(sort: v)),
                itemBuilder: (_) => [
                  for (final e in {'relevance': 'Recommended', 'price_asc': 'Price: low to high', 'price_desc': 'Price: high to low', 'rating': 'Guest rating', if (q.lat != null) 'distance': 'Distance'}.entries)
                    CheckedPopupMenuItem(value: e.key, checked: q.sort == e.key, child: Text(e.value)),
                ],
                child: IgnorePointer(child: WChip({'relevance': 'Recommended', 'price_asc': 'Price ↑', 'price_desc': 'Price ↓', 'rating': 'Top rated', 'distance': 'Nearest'}[q.sort] ?? 'Sort', icon: Icons.swap_vert_rounded)),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: Tokens.border)),
                child: Row(children: [
                  _toggle(Icons.view_agenda_outlined, !showMap, () => setState(() => showMap = false), 'List view'),
                  _toggle(Icons.map_outlined, showMap, () => setState(() => showMap = true), 'Map view'),
                ]),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Text(
              _items.isEmpty && _loading ? 'Searching…' : '$_total stay${_total == 1 ? '' : 's'}${q.hasDates ? ' · $nights night${nights == 1 ? '' : 's'}, totals shown' : ' · add dates for real availability'}',
              style: Type.body(13, color: Tokens.inkMuted, weight: FontWeight.w700),
            ),
          ),
        ),
        if (_items.isEmpty && _loading) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonList(count: 3, itemHeight: 300))),
        if (_items.isEmpty && !_loading && _error != null) SliverToBoxAdapter(child: ErrorState(error: _error!, onRetry: _reload)),
        if (_items.isEmpty && !_loading && _error == null)
          SliverToBoxAdapter(
            child: EmptyState(
              title: 'No stays match',
              message: q.hasDates ? 'There may be no availability for these dates and guests. Try different dates, fewer filters or another destination.' : 'Try widening your price range or removing a filter.',
              action: OutlinedButton(onPressed: () => _set(StayQuery(destination: q.destination, checkIn: q.checkIn, checkOut: q.checkOut, adults: q.adults, children: q.children, rooms: q.rooms)), child: const Text('Clear filters')),
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
                    MapPoint(lat: (s['lat'] as num).toDouble(), lng: (s['lng'] as num).toDouble(), title: s['name'] as String, subtitle: '${ref.read(moneyProvider)(s['price_from'] as num)} / night', kind: 'stay'),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (_, i) => Reveal(delay: Duration(milliseconds: 40 * (i % 4)), child: StayCard(_items[i], nights: _nights, query: urlQ)),
            ),
          ),
        if (_loading && _items.isNotEmpty) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))))),
        SliverToBoxAdapter(child: SizedBox(height: dockClearance(context))),
      ])),
    );
  }

  Widget _toggle(IconData i, bool on, VoidCallback f, String label) => Pressable(
        onTap: f,
        radius: 99,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: on ? Tokens.primary : Colors.transparent, borderRadius: BorderRadius.circular(99)),
          child: Icon(i, size: 20, color: on ? Colors.white : Tokens.inkMuted),
        ),
      );
}

int _activeCount(StayQuery q) =>
    (q.minPrice != null ? 1 : 0) + (q.maxPrice != null ? 1 : 0) + q.stars.length + q.amenities.length + q.types.length + (q.freeCancellation ? 1 : 0) +
    (q.breakfast ? 1 : 0) + (q.familyFriendly ? 1 : 0) + (q.minRating != null ? 1 : 0);

class _Filters extends ConsumerWidget {
  const _Filters({required this.q, required this.onChanged});
  final StayQuery q;
  final ValueChanged<StayQuery> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(metaProvider).value;
    final amenities = ((meta?['amenities'] as List?) ?? const []).cast<Map>();
    const types = {'hotel': 'Hotel', 'guesthouse': 'Guesthouse', 'resort': 'Resort', 'hostel': 'Hostel', 'boutique': 'Boutique', 'villa': 'Villa', 'apartment': 'Apartment'};
    final money = ref.watch(moneyProvider);
    final range = RangeValues(q.minPrice ?? 0, q.maxPrice ?? 300);

    Widget group(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Type.body(15, weight: FontWeight.w800)), const SizedBox(height: 12), child]),
        );
    Widget sw(String label, bool v, ValueChanged<bool> f) => SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, activeThumbColor: Tokens.primary, title: Text(label, style: Type.body(14.5, weight: FontWeight.w600)), value: v, onChanged: f);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Filters', style: Type.display(28))),
        if (_activeCount(q) > 0)
          TextButton(onPressed: () => onChanged(StayQuery(destination: q.destination, q: q.q, checkIn: q.checkIn, checkOut: q.checkOut, adults: q.adults, children: q.children, rooms: q.rooms, sort: q.sort)), child: const Text('Clear all')),
      ]),
      const SizedBox(height: 16),
      group(
        'Price per night · ${money(range.start)} – ${money(range.end)}${q.maxPrice == null ? '+' : ''}',
        RangeSlider(
          values: range,
          min: 0,
          max: 300,
          divisions: 30,
          activeColor: Tokens.primary,
          labels: RangeLabels(money(range.start), money(range.end)),
          onChanged: (v) => onChanged(q.copyWith(minPrice: v.start <= 0 ? null : v.start, maxPrice: v.end >= 300 ? null : v.end)),
        ),
      ),
      group(
        'Star rating',
        Wrap(spacing: 8, runSpacing: 8, children: [for (final s in [5, 4, 3, 2, 1]) WChip('$s ★', selected: q.stars.contains(s), onTap: () => onChanged(q.copyWith(stars: q.stars.contains(s) ? ({...q.stars}..remove(s)) : {...q.stars, s})))]),
      ),
      group('Guest rating', Wrap(spacing: 8, children: [for (final r in [4.5, 4.0, 3.5]) WChip('$r+', selected: q.minRating == r, onTap: () => onChanged(q.copyWith(minRating: q.minRating == r ? null : r)))])),
      group(
        'Property type',
        Wrap(spacing: 8, runSpacing: 8, children: [for (final e in types.entries) WChip(e.value, selected: q.types.contains(e.key), onTap: () => onChanged(q.copyWith(types: q.types.contains(e.key) ? ({...q.types}..remove(e.key)) : {...q.types, e.key})))]),
      ),
      group('Popular', Column(children: [
        sw('Free cancellation', q.freeCancellation, (v) => onChanged(q.copyWith(freeCancellation: v))),
        sw('Breakfast available', q.breakfast, (v) => onChanged(q.copyWith(breakfast: v))),
        sw('Family friendly', q.familyFriendly, (v) => onChanged(q.copyWith(familyFriendly: v))),
      ])),
      group(
        'Amenities',
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in amenities) WChip(a['label'] as String, selected: q.amenities.contains(a['code']), onTap: () => onChanged(q.copyWith(amenities: q.amenities.contains(a['code']) ? ({...q.amenities}..remove(a['code'])) : {...q.amenities, a['code'] as String}))),
        ]),
      ),
    ]);
  }
}
