import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/save.dart';
import '../../core/widgets/widgets.dart';
import '../maps/place_map.dart';
import 'places_screen.dart';

class DestinationsScreen extends ConsumerStatefulWidget {
  const DestinationsScreen({super.key, this.initialTag});
  final String? initialTag;
  @override
  ConsumerState<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends ConsumerState<DestinationsScreen> {
  late DestQuery q = DestQuery(tag: widget.initialTag);
  final _search = TextEditingController();

  static const tags = [
    'culture',
    'food',
    'temples',
    'beach',
    'nature',
    'family',
    'relaxed',
    'city',
    'islands',
    'history',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(destinationsProvider(q));
    return Scaffold(
      body: CustomScrollView(
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
              title: Text(
                context.l10n.destinationsTitle,
                style: Type.display(26),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: context.l10n.sort,
                icon: const Icon(Icons.swap_vert_rounded),
                onSelected: (v) =>
                    setState(() => q = q.copyWith(sort: v, page: 1)),
                itemBuilder: (_) => [
                  for (final e in {
                    'popularity': context.l10n.sortPopular,
                    'name': context.l10n.sortNameAZ,
                    'budget_asc': context.l10n.sortBudgetLow,
                    'budget_desc': context.l10n.sortBudgetHigh,
                  }.entries)
                    menuChoice(e.key, e.value, selected: q.sort == e.key),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.searchDestinations,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: q.q == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => q = q.copyWith(q: null, page: 1));
                          },
                        ),
                ),
                onSubmitted: (v) => setState(
                  () => q = q.copyWith(
                    q: v.trim().isEmpty ? null : v.trim(),
                    page: 1,
                  ),
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
                  WChip(
                    context.l10n.all,
                    selected: q.tag == null && q.international == null,
                    onTap: () => setState(() => q = const DestQuery()),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    color: Tokens.border,
                  ),
                  for (final t in tags) ...[
                    WChip(
                      categoryLabel(context.l10n, t),
                      selected: q.tag == t,
                      onTap: () => setState(
                        () =>
                            q = q.copyWith(tag: q.tag == t ? null : t, page: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          res.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SkeletonList(count: 3, itemHeight: 260),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorState(
                error: e,
                onRetry: () => ref.invalidate(destinationsProvider(q)),
              ),
            ),
            data: (r) {
              final items = (r['items'] as List).cast<Json>();
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    title: context.l10n.noDestinationsMatch,
                    message: context.l10n.noDestinationsHint,
                    action: OutlinedButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        q = const DestQuery();
                      }),
                      child: Text(context.l10n.clearFilters),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          context.l10n.destinationsCount(r['total'] as int),
                          style: Type.body(
                            13,
                            color: Tokens.inkMuted,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.74,
                          ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => Reveal(
                        delay: Duration(milliseconds: 40 * (i % 6)),
                        child: DestinationCard(items[i], aspect: 0.74),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 40 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}

class DestinationDetailScreen extends ConsumerStatefulWidget {
  const DestinationDetailScreen({super.key, required this.slug});
  final String slug;
  @override
  ConsumerState<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState
    extends ConsumerState<DestinationDetailScreen> {
  String? kind;
  bool recorded = false;
  bool expanded = false;
  int _img = 0;

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(destinationProvider(widget.slug));
    return StatusTone.light(
      child: Scaffold(
        body: res.when(
          loading: () => const _DetailSkeleton(),
          error: (e, _) => SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: BackButton(onPressed: () => context.pop()),
                  ),
                ),
                Expanded(
                  child: ErrorState(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(destinationProvider(widget.slug)),
                  ),
                ),
              ],
            ),
          ),
          data: _content,
        ),
      ),
    );
  }

  Widget _content(Json d) {
    if (!recorded) {
      recorded = true;
      Future.microtask(
        () => ref
            .read(recentProvider.notifier)
            .add('destination', d['slug'] as String, d['name'] as String),
      );
    }
    final money = ref.watch(moneyProvider);
    final images = (d['images'] as List).cast<Json>();
    final photos = images.isEmpty
        ? [d['cover_image']]
        : images.map((i) => i['url']).toList();
    final places = ref.watch(
      destinationPlacesProvider((slug: widget.slug, kind: kind)),
    );
    final related = (d['related'] as List).cast<Json>();
    final hotels = (d['top_accommodations'] as List).cast<Json>();
    final guides = (d['guides'] as List).cast<Json>();
    final desc = d['long_description'] as String;
    final top = MediaQuery.paddingOf(context).top;

    Widget fact(IconData icon, String title, String body) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Tokens.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: Tokens.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Type.body(14, weight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: Type.body(13.5, color: Tokens.inkSoft, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 430,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              automaticallyImplyLeading: false,
              backgroundColor: Tokens.primaryText,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 64,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                child: GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: SaveHeart(kind: 'destination', id: d['id'] as String),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: photos.length,
                      onPageChanged: (i) => setState(() => _img = i),
                      itemBuilder: (_, i) => WImage(
                        photos[i] as String?,
                        full: true,
                        width: double.infinity,
                        height: double.infinity,
                        label: context.l10n.photoOf('${d['name']}'),
                      ),
                    ),
                    const Scrim(top: true, strength: 0.85),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 52,
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d['region'] ?? ''}${d['region'] != null ? ' · ' : ''}${d['country']}'
                                  .toUpperCase(),
                              style: Type.label(11, color: Tokens.onDarkAccent),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d['name'] as String,
                              style: Type.display(
                                44,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (photos.length > 1)
                      Positioned(
                        right: 24,
                        bottom: 62,
                        child: Glass(
                          radius: 99,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          tint: const Color(0x550F172A),
                          child: Text(
                            context.l10n.photoIndex(_img + 1, photos.length),
                            style: Type.body(
                              12,
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Container(
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Tokens.pageBg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Pill(
                          context.l10n.budgetPerDay(
                            money(d['daily_budget_usd'] as num),
                          ),
                          icon: Icons.payments_outlined,
                        ),
                        if (d['best_period'] != null)
                          Pill(
                            ((d['best_period'] as String)
                                .split(';')
                                .first
                                .split('.')
                                .first),
                            icon: Icons.wb_sunny_outlined,
                            color: Tokens.primary,
                          ),
                        Pill(
                          d['currency'] as String,
                          icon: Icons.currency_exchange_rounded,
                          color: Tokens.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: Text(
                        desc,
                        maxLines: expanded ? null : 4,
                        overflow: expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: Type.body(
                          16,
                          height: 1.65,
                          color: Tokens.inkSoft,
                        ),
                      ),
                    ),
                    if (desc.length > 200)
                      TextButton(
                        onPressed: () => setState(() => expanded = !expanded),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          expanded
                              ? context.l10n.showLess
                              : context.l10n.readMore,
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (d['best_period'] != null)
                      fact(
                        Icons.wb_sunny_outlined,
                        'Best time to go',
                        d['best_period'] as String,
                      ),
                    if (d['transport_info'] != null)
                      fact(
                        Icons.directions_bus_outlined,
                        'Getting around',
                        d['transport_info'] as String,
                      ),
                    if (d['practical_info'] != null)
                      fact(
                        Icons.info_outline_rounded,
                        'Good to know',
                        d['practical_info'] as String,
                      ),
                    if (d['estimated_daily_budget_note'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          d['estimated_daily_budget_note'] as String,
                          style: Type.body(12, color: Tokens.inkMuted),
                        ),
                      ),
                    const SizedBox(height: 18),
                    PlaceMap(
                      height: 210,
                      radius: 24,
                      points: [
                        MapPoint(
                          lat: (d['lat'] as num).toDouble(),
                          lng: (d['lng'] as num).toDouble(),
                          title: d['name'] as String,
                          subtitle: d['country'] as String?,
                          kind: 'destination',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionTitle(
                context.l10n.thingsToDo,
                eyebrow: context.l10n.explore,
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final (label, value) in [
                      (context.l10n.all, null),
                      (context.l10n.kindAttractions, 'attraction'),
                      (context.l10n.kindActivities, 'activity'),
                      (context.l10n.kindRestaurants, 'restaurant'),
                    ]) ...[
                      WChip(
                        label,
                        selected: kind == value,
                        onTap: () => setState(() => kind = value),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: AsyncView<Json>(
                  value: places,
                  onRetry: () => ref.invalidate(
                    destinationPlacesProvider((slug: widget.slug, kind: kind)),
                  ),
                  loading: const SkeletonList(count: 3, itemHeight: 96),
                  data: (p) {
                    final items = (p['items'] as List).cast<Json>();
                    if (items.isEmpty) {
                      return EmptyState(
                        title: context.l10n.nothingListed,
                        message: context.l10n.nothingListedHint,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final it in items.take(8))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PlaceTile(
                              it,
                              onTap: () => showPlaceSheet(context, ref, it),
                            ),
                          ),
                        if (items.length > 8)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OutlinedButton.icon(
                              onPressed: () => _allPlaces(items),
                              icon: const Icon(Icons.expand_more_rounded),
                              label: Text(
                                context.l10n.showAllCount(items.length),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        PlaceMap(
                          height: 300,
                          radius: 24,
                          points: [
                            for (final it in items.where(
                              (i) => i['lat'] != null,
                            ))
                              MapPoint(
                                lat: (it['lat'] as num).toDouble(),
                                lng: (it['lng'] as num).toDouble(),
                                title: it['name'] as String,
                                subtitle: it['category'] as String?,
                                kind: it['kind'] == 'restaurant'
                                    ? 'restaurant'
                                    : 'place',
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (hotels.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionTitle(
                  context.l10n.whereToStay,
                  eyebrow: context.l10n.staysEyebrow,
                  action: context.l10n.seeAll,
                  onAction: () => context.go('/stays?destination=${d['slug']}'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 372,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: hotels.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (_, i) => StayCard(
                      {
                        ...hotels[i],
                        'price_from': hotels[i]['from_price_usd'],
                        'destination_name': d['name'],
                      },
                      compact: true,
                      width: 272,
                    ),
                  ),
                ),
              ),
            ],
            if (related.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionTitle(
                  context.l10n.nearbyAndRelated,
                  eyebrow: context.l10n.keepGoing,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: related.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        DestinationCard(
                          related[i],
                          width: 210,
                          aspect: 0.7,
                          showSave: false,
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Pill(
                            context.l10n.kmShort(
                              '${related[i]['distance_km']}',
                            ),
                            icon: Icons.near_me_outlined,
                            color: Tokens.accent,
                            solid: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (guides.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionTitle(
                  context.l10n.travelGuides,
                  eyebrow: context.l10n.readAndAsk,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (final g in guides)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Pressable(
                            onTap: () => context.push(
                              '/assistant?q=${Uri.encodeComponent(g['title'] as String)}&destination=${d['slug']}',
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Tokens.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Tokens.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book_rounded,
                                    color: Tokens.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      g['title'] as String,
                                      style: Type.body(
                                        14.5,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: Tokens.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (d['image_credit'] != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    d['image_credit'] as String,
                    style: Type.body(12, color: Tokens.inkMuted),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12 + MediaQuery.paddingOf(context).bottom,
          child: Glass(
            radius: 26,
            blur: 22,
            tint: const Color(0xE6FFFFFF),
            border: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.go('/stays?destination=${d['slug']}'),
                    icon: const Icon(Icons.bed_rounded, size: 20),
                    label: Text(context.l10n.findStays),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/trips/new?destination=${d['slug']}'),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(context.l10n.planTrip),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (top > 0) const SizedBox.shrink(),
      ],
    );
  }

  void _allPlaces(List<Json> items) {
    showModalBottomSheet<void>(
      useRootNavigator:
          true, // cover the bottom bar instead of sliding under it
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (c, sc) => ListView.separated(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => PlaceTile(
            items[i],
            onTap: () {
              Navigator.pop(c);
              showPlaceSheet(context, ref, items[i]);
            },
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 380,
        decoration: const BoxDecoration(gradient: Tokens.dusk),
      ),
      const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonList(count: 3, itemHeight: 90),
      ),
    ],
  );
}
