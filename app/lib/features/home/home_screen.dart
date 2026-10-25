import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';
import '../stays/search_panel.dart';

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Late night wanderer';
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final recent = ref.watch(recentProvider);
    final auth = ref.watch(authProvider);
    final name = auth.signedIn ? (auth.user!['name'] as String).split(' ').first : null;

    return RefreshIndicator(
      color: Tokens.primary,
      edgeOffset: MediaQuery.paddingOf(context).top + 8,
      onRefresh: () async {
        ref.invalidate(homeProvider);
        await ref.read(homeProvider.future).catchError((_) => <String, dynamic>{});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _Hero(featured: home.value == null ? const [] : (home.value!['featured'] as List).cast<Json>(), name: name, signedIn: auth.signedIn)),
          SliverToBoxAdapter(
            child: home.when(
              loading: () => const Padding(padding: EdgeInsets.fromLTRB(20, 100, 20, 0), child: SkeletonList(count: 2, itemHeight: 240)),
              error: (e, _) => Padding(padding: const EdgeInsets.only(top: 80), child: ErrorState(error: e, onRetry: () => ref.invalidate(homeProvider))),
              data: (h) => _Body(h: h, recent: recent),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: dockClearance(context))),
        ],
      ),
    );
  }
}

/// Full-bleed destination slideshow with the greeting, headline and search pill laid over it.
class _Hero extends ConsumerStatefulWidget {
  const _Hero({required this.featured, required this.name, required this.signedIn});
  final List<Json> featured;
  final String? name;
  final bool signedIn;

  @override
  ConsumerState<_Hero> createState() => _HeroState();
}

class _HeroState extends ConsumerState<_Hero> {
  final _page = PageController();
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.featured.length < 2 || !_page.hasClients) return;
      _page.nextPage(duration: const Duration(milliseconds: 900), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final h = (MediaQuery.sizeOf(context).height * 0.6).clamp(440.0, 600.0);
    final f = widget.featured;
    final current = f.isEmpty ? null : f[_i % f.length];
    final unread = widget.signedIn ? (ref.watch(notificationsProvider).value?['unread'] as int? ?? 0) : 0;

    return SizedBox(
      height: h + 56,
      child: Stack(clipBehavior: Clip.none, children: [
        SizedBox(
          height: h,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
            child: Stack(fit: StackFit.expand, children: [
              Container(decoration: const BoxDecoration(gradient: Tokens.dusk)),
              if (f.isNotEmpty)
                PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _i = i),
                  itemBuilder: (_, i) => WImage(f[i % f.length]['cover_image'] as String?, full: true, width: double.infinity, height: double.infinity),
                ),
              const Scrim(top: true, strength: 0.88),
              Positioned(
                top: top + 10,
                left: 20,
                right: 20,
                child: Row(children: [
                  const Icon(Icons.explore_rounded, color: Tokens.onDarkAccent, size: 26),
                  const SizedBox(width: 8),
                  Text('WAYFARER', style: Type.display(17, color: Colors.white, spacing: 3.2, weight: FontWeight.w600)),
                  const Spacer(),
                  if (widget.signedIn)
                    Stack(clipBehavior: Clip.none, children: [
                      GlassIconButton(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onTap: () => context.push('/notifications')),
                      if (unread > 0) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Tokens.primaryText, shape: BoxShape.circle), child: Text('$unread', style: Type.body(10, color: Colors.white, weight: FontWeight.w800)))),
                    ])
                  else
                    Pressable(
                      onTap: () => context.push('/login'),
                      radius: 99,
                      child: Glass(radius: 99, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), tint: const Color(0x400F172A), child: Text('Sign in', style: Type.body(13, color: Colors.white, weight: FontWeight.w700))),
                    ),
                ]),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 78,
                child: Reveal(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.name != null ? '${_greeting()}, ${widget.name}'.toUpperCase() : _greeting().toUpperCase(), style: Type.label(11.5, color: Tokens.onDarkAccent)),
                    const SizedBox(height: 12),
                    Text('Where will you', style: Type.display(42, color: Colors.white, height: 1.0)),
                    Text('wander next?', style: Type.display(42, color: Tokens.onDarkAccent, height: 1.05, italic: true, weight: FontWeight.w500)),
                    const SizedBox(height: 14),
                    if (current != null)
                      Pressable(
                        onTap: () => context.push('/destinations/${current['slug']}'),
                        radius: 99,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.place_rounded, size: 16, color: Tokens.onDarkMuted),
                          const SizedBox(width: 4),
                          Text('${current['name']}, ${current['country']}', style: Type.body(13.5, color: Colors.white, weight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 15, color: Tokens.onDarkMuted),
                        ]),
                      ),
                  ]),
                ),
              ),
              if (f.length > 1)
                Positioned(
                  right: 24,
                  bottom: 84,
                  child: Row(children: [
                    for (var i = 0; i < f.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(left: 4),
                        width: i == _i % f.length ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(color: i == _i % f.length ? Tokens.onDarkAccent : Colors.white54, borderRadius: BorderRadius.circular(6)),
                      ),
                  ]),
                ),
            ]),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: Pressable(
            onTap: () => showSearchSheet(context),
            scale: 0.98,
            radius: 24,
            semanticLabel: 'Search stays',
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(24), boxShadow: Tokens.softShadow(0.18)),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: Tokens.primary.withValues(alpha: .1), shape: BoxShape.circle), child: const Icon(Icons.search_rounded, color: Tokens.primary)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Find your stay', style: Type.body(15.5, weight: FontWeight.w800)),
                    Text('Anywhere · Any dates · Any guests', style: Type.body(12.5, color: Tokens.inkMuted)),
                  ]),
                ),
                const Icon(Icons.tune_rounded, color: Tokens.inkMuted),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.h, required this.recent});
  final Json h;
  final List<Map<String, String>> recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = (h['featured'] as List).cast<Json>();
    final trending = (h['trending'] as List).cast<Json>();
    final hotels = (h['hotels'] as List).cast<Json>();
    final trips = (h['itineraries'] as List).cast<Json>();
    final cats = (h['categories'] as List).cast<Json>().where((c) => c['category'] != 'food').take(12).toList();
    final counts = h['counts'] as Map;
    final money = ref.watch(moneyProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 22),
      _QuickActions(),
      _Stats(counts: counts),
      if (recent.isNotEmpty) ...[
        const SectionTitle('Pick up where you left off', eyebrow: 'Recently viewed'),
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final r = recent[i];
              return WChip(r['name']!, icon: r['kind'] == 'stay' ? Icons.bed_outlined : Icons.place_outlined, onTap: () => context.push(r['kind'] == 'stay' ? '/stays/${r['slug']}' : '/destinations/${r['slug']}'));
            },
          ),
        ),
      ],
      SectionTitle('Destinations we love', eyebrow: 'Featured', action: 'See all', onAction: () => context.push('/destinations')),
      _DestinationPager(items: featured),
      const SectionTitle('Browse by mood', eyebrow: 'Explore'),
      SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final c = cats[i];
            return WChip(capitalize(c['category'] as String), icon: categoryIcon(c['category'] as String), count: c['count'] as int?, onTap: () => context.push('/places?category=${c['category']}'));
          },
        ),
      ),
      SectionTitle('Stays worth the trip', eyebrow: 'Top rated', action: 'Browse', onAction: () => context.go('/stays')),
      SizedBox(
        height: 372,
        child: ListView.separated(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: hotels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (_, i) => Reveal(delay: Duration(milliseconds: 60 * i), child: StayCard({...hotels[i], 'price_from': hotels[i]['from_price_usd']}, compact: true, width: 272)),
        ),
      ),
      SectionTitle('Ready-made journeys', eyebrow: 'Itineraries', action: 'Plan yours', onAction: () => context.go('/trips')),
      SizedBox(
        height: 280,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: trips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) => _TripCard(trip: trips[i], money: money),
        ),
      ),
      const SectionTitle('Trending now', eyebrow: 'This week'),
      for (final (i, d) in trending.take(5).indexed)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Reveal(delay: Duration(milliseconds: 70 * i), child: _TrendRow(rank: i + 1, d: d)),
        ),
      const SizedBox(height: 28),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _Honesty()),
    ]);
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, VoidCallback)>[
      (Icons.auto_awesome_rounded, 'AI planner', 'Day-by-day', () => context.push('/trips/new')),
      (Icons.chat_bubble_rounded, 'Ask guide', 'Instant answers', () => context.push('/assistant')),
      (Icons.map_rounded, 'Map', 'Near you', () => context.push('/map')),
      (Icons.attractions_rounded, 'Places', 'Things to do', () => context.push('/places')),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final (icon, title, sub, onTap) = items[i];
          return Reveal(
            delay: Duration(milliseconds: 80 * i),
            child: Pressable(
              onTap: onTap,
              child: Container(
                width: 132,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Tokens.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Tokens.border),
                  boxShadow: Tokens.softShadow(0.08),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 34, height: 34, decoration: const BoxDecoration(color: Tokens.tint, shape: BoxShape.circle), child: Icon(icon, color: Tokens.primary, size: 19)),
                  const Spacer(),
                  Text(title, style: Type.body(14.5, color: Tokens.ink, weight: FontWeight.w800)),
                  Text(sub, style: Type.body(11.5, color: Tokens.inkMuted)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.counts});
  final Map counts;

  @override
  Widget build(BuildContext context) {
    Widget stat(num v, String l) => Expanded(
          child: Column(children: [
            CountUp(value: v.toDouble(), builder: (x) => Text('${x.round()}', style: Type.display(28, color: Tokens.primaryText))),
            const SizedBox(height: 2),
            Text(l.toUpperCase(), style: Type.label(10)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: Tokens.border)),
        child: Row(children: [
          stat(counts['destinations'] as num, 'Destinations'),
          Container(width: 1, height: 34, color: Tokens.border),
          stat(counts['places'] as num, 'Places'),
          Container(width: 1, height: 34, color: Tokens.border),
          stat(counts['accommodations'] as num, 'Stays'),
        ]),
      ),
    );
  }
}

/// Snapping carousel whose centred card is full size and whose neighbours recede.
class _DestinationPager extends StatefulWidget {
  const _DestinationPager({required this.items});
  final List<Json> items;
  @override
  State<_DestinationPager> createState() => _DestinationPagerState();
}

class _DestinationPagerState extends State<_DestinationPager> {
  final _c = PageController(viewportFraction: 0.76);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 380,
        child: PageView.builder(
          controller: _c,
          padEnds: true,
          clipBehavior: Clip.none,
          itemCount: widget.items.length,
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final p = _c.hasClients && _c.position.haveDimensions ? (_c.page ?? 0) - i : (i == 0 ? 0.0 : 1.0);
              final s = (1 - p.abs() * 0.1).clamp(0.88, 1.0);
              return Transform.scale(scale: s, child: Opacity(opacity: (1 - p.abs() * 0.35).clamp(0.55, 1.0), child: child));
            },
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: DestinationCard(widget.items[i], aspect: 0.72)),
          ),
        ),
      );
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.money});
  final Json trip;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => context.push('/trips/${trip['id']}'),
        child: Container(
          width: 236,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Tokens.radius), boxShadow: Tokens.softShadow(0.12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius),
            child: Stack(fit: StackFit.expand, children: [
              WImage(trip['cover_image'] as String?, width: double.infinity, height: double.infinity),
              const Scrim(top: true, strength: 0.9),
              Positioned(left: 14, top: 14, child: Pill('${trip['num_days']} DAY${trip['num_days'] == 1 ? '' : 'S'}', color: Tokens.accent, solid: true, icon: Icons.route_rounded)),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${trip['destination_name']}'.toUpperCase(), style: Type.label(10.5, color: Tokens.onDarkMuted)),
                  const SizedBox(height: 4),
                  Text(trip['title'] as String, style: Type.display(19, color: Colors.white, height: 1.12), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('Est. ${money(trip['est_total_usd'] as num)}', style: Type.body(12.5, color: Tokens.onDarkAccent, weight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.rank, required this.d});
  final int rank;
  final Json d;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => context.push('/destinations/${d['slug']}'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: Tokens.border)),
          child: Row(children: [
            SizedBox(width: 38, child: Text('$rank', style: Type.display(34, color: rank <= 3 ? Tokens.primary : Tokens.border, italic: true))),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['name'] as String, style: Type.display(20, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(d['country'] as String, style: Type.body(12.5, color: Tokens.inkMuted)),
              ]),
            ),
            const SizedBox(width: 10),
            WImage(d['cover_image'] as String?, width: 64, height: 64, radius: 16),
          ]),
        ),
      );
}

class _Honesty extends StatelessWidget {
  const _Honesty();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Tokens.tint, borderRadius: BorderRadius.circular(22)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: Tokens.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'WAYFARER is an academic capstone. Landmarks are real places with indicative prices and hours; hotels, restaurants, reviews, bookings and payments are educational sample data, and no money moves.',
              style: Type.body(12.5, color: Tokens.inkMuted, height: 1.5),
            ),
          ),
        ]),
      );
}
