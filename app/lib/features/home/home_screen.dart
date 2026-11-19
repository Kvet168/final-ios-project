import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/save.dart';
import '../../core/widgets/settings_ui.dart';
import '../../core/widgets/widgets.dart';
import '../ads/ads.dart';
import '../auth/auth_controller.dart';
import '../stays/search_panel.dart';

/// The clock the greeting reads; tests pin it so screenshots do not change with the time of day.
@visibleForTesting
DateTime Function() homeClock = DateTime.now;

String _greeting(AppLocalizations l) {
  final h = homeClock().hour;
  if (h < 5) return l.greetingNight;
  if (h < 12) return l.greetingMorning;
  if (h < 18) return l.greetingAfternoon;
  return l.greetingEvening;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// The floating header shows once the hero has scrolled away and the reader keeps scrolling down, and closes again
  /// as soon as they scroll back up.
  bool _showBar = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 ||
        n.metrics.axis != Axis.vertical ||
        n is! ScrollUpdateNotification) {
      return false;
    }
    final y = n.metrics.pixels, dy = n.scrollDelta ?? 0;
    var next = _showBar;
    if (y < 220) {
      next = false;
    } else if (dy > 2) {
      next = true;
    } else if (dy < -2) {
      next = false;
    }
    if (next != _showBar) setState(() => _showBar = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final recent = ref.watch(recentProvider);
    final auth = ref.watch(authProvider);
    final name = auth.signedIn
        ? (auth.user!['name'] as String).split(' ').first
        : null;

    final scroll = RefreshIndicator(
      color: Tokens.primary,
      edgeOffset: MediaQuery.paddingOf(context).top + 8,
      onRefresh: () async {
        ref.invalidate(homeProvider);
        await ref
            .read(homeProvider.future)
            .catchError((_) => <String, dynamic>{});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(
              featured: home.value == null
                  ? const []
                  : (home.value!['featured'] as List).cast<Json>(),
              name: name,
              signedIn: auth.signedIn,
            ),
          ),
          SliverToBoxAdapter(
            child: home.when(
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(20, 100, 20, 0),
                child: SkeletonList(count: 2, itemHeight: 240),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 80),
                child: ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(homeProvider),
                ),
              ),
              data: (h) => _Body(h: h, recent: recent),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: dockClearance(context))),
        ],
      ),
    );
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: scroll,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_showBar,
            child: AnimatedSlide(
              offset: _showBar ? Offset.zero : const Offset(0, -1.4),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showBar ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: const _FloatingBar(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bell (with unread count) and profile button. [dark] is for use on the light floating bar.
class _HeaderActions extends ConsumerWidget {
  const _HeaderActions({this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final unread = auth.signedIn
        ? (ref.watch(notificationsProvider).value?['unread'] as int? ?? 0)
        : 0;
    final initial = auth.signedIn
        ? ((auth.user!['name'] as String).trim().isEmpty
              ? '?'
              : (auth.user!['name'] as String).trim()[0].toUpperCase())
        : null;
    final fg = dark ? Tokens.ink : Colors.white;
    final bg = dark ? Tokens.neutralTint : const Color(0x400F172A);

    Widget circle(Widget child, VoidCallback onTap, String label) => Pressable(
      onTap: onTap,
      radius: 99,
      semanticLabel: label,
      child: dark
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Center(child: child),
            )
          : Glass(
              radius: 99,
              tint: bg,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: child),
              ),
            ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            circle(
              Icon(Icons.notifications_none_rounded, color: fg, size: 22),
              () => context.push('/notifications'),
              context.l10n.notifications,
            ),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Tokens.primary,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: Type.body(
                      10,
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        circle(
          initial == null
              ? Icon(Icons.person_outline_rounded, color: fg, size: 22)
              : ((auth.user!['avatarUrl'] as String?)?.isNotEmpty ?? false)
              ? ProfileAvatar(
                  name: auth.user!['name'] as String,
                  url: auth.user!['avatarUrl'] as String?,
                  size: 40,
                )
              : Text(
                  initial,
                  style: Type.body(15, color: fg, weight: FontWeight.w700),
                ),
          () => context.go('/account'),
          context.l10n.tabMe,
        ),
      ],
    );
  }
}

/// Compact header docked to the top edge (under the status bar) while the reader scrolls down.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 6, 12, 8),
      decoration: const BoxDecoration(
        color: Tokens.surface,
        border: Border(bottom: BorderSide(color: Tokens.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/logo.png', height: 28),
          const Spacer(),
          const _HeaderActions(dark: true),
        ],
      ),
    );
  }
}

/// Full-bleed destination slideshow with the greeting, headline and search pill laid over it.
class _Hero extends ConsumerStatefulWidget {
  const _Hero({
    required this.featured,
    required this.name,
    required this.signedIn,
  });
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
      _page.nextPage(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
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
    final h = (MediaQuery.sizeOf(context).height * 0.42).clamp(320.0, 420.0);
    final f = widget.featured;
    final current = f.isEmpty ? null : f[_i % f.length];
    return SizedBox(
      height: h + 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: h,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(gradient: Tokens.dusk),
                  ),
                  if (f.isNotEmpty)
                    PageView.builder(
                      controller: _page,
                      onPageChanged: (i) => setState(() => _i = i),
                      itemBuilder: (_, i) => WImage(
                        f[i % f.length]['cover_image'] as String?,
                        full: true,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  const Scrim(top: true, strength: 0.88),
                  Positioned(
                    top: top + 10,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Image.asset('assets/logo.png', height: 30),
 const Spacer(),
                        const _HeaderActions(),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 78,
                    child: Reveal(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name != null
                                ? context.l10n
                                      .greetingWithName(
                                        _greeting(context.l10n),
                                        widget.name!,
                                      )
                                      .toUpperCase()
                                : _greeting(context.l10n).toUpperCase(),
                            style: Type.label(11.5, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.heroLine1,
                            style: Type.display(
                              context.isKhmer ? 34 : 42,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            context.l10n.heroLine2,
                            style: Type.display(
                              context.isKhmer ? 34 : 42,
                              color: Tokens.onDarkAccent,
                              height: 1.05,
                              italic: true,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (current != null)
                            Pressable(
                              onTap: () => context.push(
                                '/destinations/${current['slug']}',
                              ),
                              radius: 99,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.place_rounded,
                                    size: 16,
                                    color: Tokens.onDarkMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${current['name']}, ${current['country']}',
                                    style: Type.body(
                                      13.5,
                                      color: Colors.white,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: Tokens.onDarkMuted,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (f.length > 1)
                    Positioned(
                      right: 24,
                      bottom: 84,
                      child: Row(
                        children: [
                          for (var i = 0; i < f.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(left: 4),
                              width: i == _i % f.length ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _i % f.length
                                    ? Tokens.onDarkAccent
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
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
              semanticLabel: context.l10n.searchStays,
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Tokens.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: Tokens.softShadow(0.18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Tokens.primary.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Tokens.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.findYourStay,
                            style: Type.body(15.5, weight: FontWeight.w800),
                          ),
                          Text(
                            context.l10n.anywhereAnyDates,
                            style: Type.body(12.5, color: Tokens.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.tune_rounded, color: Tokens.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
    final cats = (h['categories'] as List)
        .cast<Json>()
        .where((c) => c['category'] != 'food')
        .take(12)
        .toList();
    final counts = h['counts'] as Map;
    final money = ref.watch(moneyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _QuickActions(),
        if (recent.isNotEmpty) ...[
          SectionTitle(
            context.l10n.pickUpWhereLeft,
            eyebrow: context.l10n.recentlyViewed,
          ),
          SizedBox(
            height: 60,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final r = recent[i];
                return WChip(
                  r['name']!,
                  icon: r['kind'] == 'stay'
                      ? Icons.bed_outlined
                      : Icons.place_outlined,
                  onTap: () => context.push(
                    r['kind'] == 'stay'
                        ? '/stays/${r['slug']}'
                        : '/destinations/${r['slug']}',
                  ),
                );
              },
            ),
          ),
        ],
        const AdBannerCarousel(),
        const FestivalStrip(),
        SectionTitle(
          context.l10n.destinationsWeLove,
          eyebrow: context.l10n.featured,
          action: context.l10n.seeAll,
          onAction: () => context.push('/destinations'),
        ),
        _DestinationRow(items: featured),
        SectionTitle(context.l10n.browseByMood, eyebrow: context.l10n.explore),
        SizedBox(
          height: 60,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = cats[i];
              return WChip(
                categoryLabel(context.l10n, c['category'] as String),
                icon: categoryIcon(c['category'] as String),
                count: c['count'] as int?,
                onTap: () => context.push('/places?category=${c['category']}'),
              );
            },
          ),
        ),
        SectionTitle(
          context.l10n.staysWorthTrip,
          eyebrow: context.l10n.topRated,
          action: context.l10n.browse,
          onAction: () => context.go('/stays'),
        ),
        SizedBox(
          height: context.isKhmer
              ? 400
              : 372, // stay cards grow with Khmer line height
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: hotels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (_, i) => Reveal(
              delay: Duration(milliseconds: 60 * i),
              child: StayCard(
                {...hotels[i], 'price_from': hotels[i]['from_price_usd']},
                compact: true,
                width: 272,
              ),
            ),
          ),
        ),
        SectionTitle(
          context.l10n.readyMadeJourneys,
          eyebrow: context.l10n.itineraries,
          action: context.l10n.planYours,
          onAction: () => context.go('/trips'),
        ),
        SizedBox(
          height: 296,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: trips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _TripCard(trip: trips[i], money: money),
          ),
        ),
        const SponsoredStories(),
        SectionTitle(context.l10n.trendingNow, eyebrow: context.l10n.thisWeek),
        for (final (i, d) in trending.take(5).indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Reveal(
              delay: Duration(milliseconds: 70 * i),
              child: _TrendRow(rank: i + 1, d: d),
            ),
          ),
        const SizedBox(height: 28),
        _Stats(counts: counts),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <(String, String, String, VoidCallback)>[
      (
        'planner',
        context.l10n.quickAiPlanner,
        context.l10n.quickDayByDay,
        () => context.push('/trips/new'),
      ),
      (
        'guide',
        context.l10n.quickAskGuide,
        context.l10n.quickInstantAnswers,
        () => context.push('/assistant'),
      ),
      (
        'map',
        context.l10n.quickMap,
        context.l10n.quickNearYou,
        () => context.push('/map'),
      ),
      (
        'places',
        context.l10n.quickPlaces,
        context.l10n.quickThingsToDo,
        () => context.push('/places'),
      ),
    ];
    return SizedBox(
      // Khmer lines are taller (stacked vowels), so the cards grow instead of overflowing.
      height: context.isKhmer ? 128 : 112,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (icon, title, sub, onTap) = items[i];
          return Reveal(
            delay: Duration(milliseconds: 80 * i),
            child: Pressable(
              onTap: onTap,
              child: Container(
                width: 124,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Tokens.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Tokens.border),
                  boxShadow: Tokens.softShadow(0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon3D(icon, size: 32),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Type.body(
                        13.5,
                        color: Tokens.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Type.body(11.5, color: Tokens.inkMuted),
                    ),
                  ],
                ),
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
      child: Column(
        children: [
          CountUp(
            value: v.toDouble(),
            builder: (x) => Text(
              '${x.round()}',
              style: Type.display(28, color: Tokens.primaryText),
            ),
          ),
          const SizedBox(height: 2),
          Text(l.toUpperCase(), style: Type.label(11)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Tokens.border),
        ),
        child: Row(
          children: [
            stat(counts['destinations'] as num, context.l10n.statDestinations),
            Container(width: 1, height: 34, color: Tokens.border),
            stat(counts['places'] as num, context.l10n.statPlaces),
            Container(width: 1, height: 34, color: Tokens.border),
            stat(counts['accommodations'] as num, context.l10n.statStays),
          ],
        ),
      ),
    );
  }
}

/// Snapping carousel whose centred card is full size and whose neighbours recede.
/// "Destinations we love": a plain horizontal row of compact photo tiles (name and daily budget over the photo).
class _DestinationRow extends ConsumerWidget {
  const _DestinationRow({required this.items});
  final List<Json> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    return SizedBox(
      height: 214,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final d = items[i];
          final budget = d['daily_budget_usd'] as num?;
          return Pressable(
            onTap: () => context.push('/destinations/${d['slug']}'),
            radius: 22,
            scale: 0.97,
            semanticLabel: '${d['name']}, ${d['country']}',
            child: SizedBox(
              width: 156,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WImage(
                      d['cover_image'] as String?,
                      full: true,
                      width: double.infinity,
                      height: double.infinity,
                      label: 'Photo of ${d['name']}',
                    ),
                    const Scrim(strength: 0.8),
                    if (d['id'] != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: SaveHeart(
                          kind: 'destination',
                          id: d['id'] as String,
                          size: 32,
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            d['name'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Type.display(
                              17,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          if (budget != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              context.l10n.fromPerDay(money(budget)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Type.body(
                                11.5,
                                color: Colors.white70,
                                weight: FontWeight.w600,
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
        },
      ),
    );
  }
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radius),
        boxShadow: Tokens.softShadow(0.12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            WImage(
              trip['cover_image'] as String?,
              width: double.infinity,
              height: double.infinity,
            ),
            const Scrim(top: true, strength: 0.9),
            Positioned(
              left: 14,
              top: 14,
              child: Pill(
                context.l10n.daysCount(trip['num_days'] as int).toUpperCase(),
                color: Tokens.accent,
                solid: true,
                icon: Icons.route_rounded,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip['destination_name']}'.toUpperCase(),
                    style: Type.label(11, color: Tokens.onDarkMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip['title'] as String,
                    style: Type.display(19, color: Colors.white, height: 1.12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.estimatedTotal(
                      money(trip['est_total_usd'] as num),
                    ),
                    style: Type.body(
                      12.5,
                      color: Tokens.onDarkAccent,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Tokens.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '$rank',
              style: Type.display(
                34,
                color: rank <= 3 ? Tokens.primary : Tokens.border,
                italic: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['name'] as String,
                  style: Type.display(20, height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  d['country'] as String,
                  style: Type.body(12.5, color: Tokens.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          WImage(
            d['cover_image'] as String?,
            width: 64,
            height: 64,
            radius: 16,
          ),
        ],
      ),
    ),
  );
}
