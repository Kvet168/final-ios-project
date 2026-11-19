import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Sponsored placements. Everything here is paid content from local businesses, and every card carries the
/// "Sponsored" label. A failing ad request never breaks a screen: the widgets simply render nothing.

/* ------------------------------ data ------------------------------ */

class AdQuery {
  const AdQuery(this.placement, {this.destination, this.q, this.limit});
  final String placement;
  final String? destination, q;
  final int? limit;

  Json toQuery() => {
    'placement': placement,
    'destination': destination,
    'q': q,
    'limit': limit,
  };
  @override
  bool operator ==(Object other) =>
      other is AdQuery && other.toQuery().toString() == toQuery().toString();
  @override
  int get hashCode => toQuery().toString().hashCode;
}

final adsProvider = FutureProvider.autoDispose.family<List<Json>, AdQuery>((
  ref,
  a,
) async {
  ref.cacheFor(const Duration(minutes: 2));
  try {
    final r = await ref.watch(apiProvider).getJson('/ads', query: a.toQuery());
    return (r['items'] as List).cast<Json>();
  } catch (_) {
    return const <Json>[];
  }
});

final sponsoredArticleProvider = FutureProvider.autoDispose
    .family<Json, String>(
      (ref, id) => ref.watch(apiProvider).getJson('/ads/$id/article'),
    );

/// Counts what travellers saw and tapped. Events are sent in small batches, and a campaign counts at most one impression per app session.
class AdTracker {
  AdTracker(this._api);
  final ApiClient _api;
  final _seen = <String>{};
  final _queue = <Json>[];
  Timer? _timer;

  void impression(String id) {
    if (_seen.add(id)) _push('impression', id);
  }

  void click(String id) => _push('click', id);

  void _push(String type, String id) {
    _queue.add({'campaignId': id, 'type': type});
    if (_queue.length >= 20) {
      flush();
    } else {
      _timer ??= Timer(const Duration(seconds: 6), flush);
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final batch = List<Json>.of(_queue.take(50));
    _queue.removeRange(0, batch.length);
    try {
      await _api.postEmpty('/ads/events', body: {'events': batch});
    } catch (_) {
      // statistics are best effort
    }
  }
}

final adTrackerProvider = Provider<AdTracker>((ref) {
  final t = AdTracker(ref.watch(apiProvider));
  ref.onDispose(t.flush);
  return t;
});

/* ------------------------------ helpers ------------------------------ */

String _text(BuildContext c, Json ad, String base) {
  final en = ad['${base}_en'] as String?, km = ad['${base}_km'] as String?;
  if (c.isKhmer && km != null && km.isNotEmpty) return km;
  return en ?? km ?? '';
}

String _business(BuildContext c, Json ad) {
  final km = ad['business_name_km'] as String?;
  if (c.isKhmer && km != null && km.isNotEmpty) return km;
  return (ad['business_name'] as String?) ?? '';
}

Future<void> _open(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Records the tap, then opens the story page for articles or a detail sheet for everything else.
void openAd(BuildContext context, WidgetRef ref, Json ad) {
  ref.read(adTrackerProvider).click(ad['id'] as String);
  if (ad['placement'] == 'sponsored_article' && ad['has_article'] == true) {
    context.push('/sponsored/${ad['id']}');
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AdSheet(ad: ad),
  );
}

/// The label that marks every paid placement.
class SponsoredBadge extends StatelessWidget {
  const SponsoredBadge({super.key, this.onImage = true});
  final bool onImage;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: onImage ? const Color(0x990F172A) : Tokens.neutralTint,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      context.l10n.sponsored.toUpperCase(),
      style: Type.label(
        10,
        color: onImage ? Colors.white : Tokens.inkMuted,
        weight: FontWeight.w800,
      ),
    ),
  );
}

/// Counts an impression the first time the card is built (cards in lists are built when they scroll near the screen).
class _Seen extends ConsumerStatefulWidget {
  const _Seen({required this.id, required this.child});
  final String id;
  final Widget child;
  @override
  ConsumerState<_Seen> createState() => _SeenState();
}

class _SeenState extends ConsumerState<_Seen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(adTrackerProvider).impression(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/* ------------------------------ cards ------------------------------ */

class AdCard extends ConsumerWidget {
  const AdCard(
    this.ad, {
    super.key,
    this.width,
    this.height,
    this.radius = 22,
    this.festival = false,
  });
  final Json ad;
  final double? width, height, radius;
  final bool festival;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _text(context, ad, 'title');
    final offer = _text(context, ad, 'offer');
    final festivalName = festival ? _text(context, ad, 'festival_name') : '';
    return _Seen(
      id: ad['id'] as String,
      child: Pressable(
        onTap: () => openAd(context, ref, ad),
        radius: radius ?? 22,
        scale: 0.98,
        semanticLabel: '${context.l10n.sponsored}: $title',
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius ?? 22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(gradient: Tokens.dusk),
                ),
                WImage(
                  ad['image_url'] as String?,
                  full: true,
                  width: double.infinity,
                  height: double.infinity,
                ),
                const Scrim(top: false, strength: 0.82),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Row(
                    children: [
                      const SponsoredBadge(),
                      if (festivalName.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Tokens.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            festivalName,
                            style: Type.body(
                              11,
                              color: Colors.white,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Type.display(
                          18,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _business(context, ad),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Type.body(
                          12.5,
                          color: Colors.white70,
                          weight: FontWeight.w600,
                        ),
                      ),
                      if (offer.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Tokens.cta,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            offer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Type.body(
                              12,
                              color: Tokens.onCta,
                              weight: FontWeight.w800,
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
      ),
    );
  }
}

/* ------------------------------ placements ------------------------------ */

/// Home page banners, rotated by the server so every paying business gets a fair share.
class AdBannerCarousel extends ConsumerStatefulWidget {
  const AdBannerCarousel({super.key});
  @override
  ConsumerState<AdBannerCarousel> createState() => _AdBannerCarouselState();
}

class _AdBannerCarouselState extends ConsumerState<AdBannerCarousel> {
  final _page = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_page.hasClients) return;
      final n =
          ref
              .read(adsProvider(const AdQuery('homepage_banner')))
              .value
              ?.length ??
          0;
      if (n < 2) return;
      _page.animateToPage(
        (_i + 1) % n,
        duration: const Duration(milliseconds: 600),
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
    final ads =
        ref.watch(adsProvider(const AdQuery('homepage_banner'))).value ??
        const <Json>[];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        children: [
          SizedBox(
            height: 188,
            child: PageView.builder(
              controller: _page,
              itemCount: ads.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AdCard(ads[i]),
              ),
            ),
          ),
          if (ads.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < ads.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _i ? Tokens.primary : Tokens.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sponsored places in Explore and on a destination page. [destination] limits it to one destination's slug.
class SponsoredStrip extends ConsumerWidget {
  const SponsoredStrip({
    super.key,
    this.destination,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 14),
  });
  final String? destination;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads =
        ref
            .watch(
              adsProvider(
                AdQuery('featured_destination', destination: destination),
              ),
            )
            .value ??
        const <Json>[];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          context.l10n.adsFeaturedTitle,
          eyebrow: context.l10n.adsFeaturedEyebrow,
          padding: padding.copyWith(top: padding.top + 12, bottom: 12),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: padding.left),
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => AdCard(
              ads[i],
              width: ads.length == 1
                  ? MediaQuery.sizeOf(context).width - padding.left * 2
                  : 268,
            ),
          ),
        ),
      ],
    );
  }
}

/// Festival and holiday promotions on the home page.
class FestivalStrip extends ConsumerWidget {
  const FestivalStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads =
        ref.watch(adsProvider(const AdQuery('festival'))).value ??
        const <Json>[];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          context.l10n.adsFestivalTitle,
          eyebrow: context.l10n.adsFestivalEyebrow,
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => AdCard(
              ads[i],
              width: ads.length == 1
                  ? MediaQuery.sizeOf(context).width - 40
                  : 280,
              festival: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Sponsored travel articles on the home page; each opens a full story page.
class SponsoredStories extends ConsumerWidget {
  const SponsoredStories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads =
        ref
            .watch(adsProvider(const AdQuery('sponsored_article', limit: 3)))
            .value ??
        const <Json>[];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          context.l10n.adsStoriesTitle,
          eyebrow: context.l10n.adsStoriesEyebrow,
        ),
        for (final ad in ads)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _StoryTile(ad),
          ),
      ],
    );
  }
}

class _StoryTile extends ConsumerWidget {
  const _StoryTile(this.ad);
  final Json ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Seen(
      id: ad['id'] as String,
      child: Pressable(
        onTap: () => openAd(context, ref, ad),
        radius: 20,
        scale: 0.985,
        semanticLabel:
            '${context.l10n.sponsored}: ${_text(context, ad, 'title')}',
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Tokens.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: Tokens.softShadow(0.08),
          ),
          child: Row(
            children: [
              WImage(
                ad['image_url'] as String?,
                width: 96,
                height: 96,
                radius: 14,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SponsoredBadge(onImage: false),
                    const SizedBox(height: 6),
                    Text(
                      _text(context, ad, 'title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Type.display(16.5, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _text(context, ad, 'body'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Type.body(13, color: Tokens.inkMuted),
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
}

/// Up to two relevant sponsored businesses above the organic search results. Nothing is shown when nothing matches.
class SponsoredSearchBlock extends ConsumerWidget {
  const SponsoredSearchBlock({super.key, this.q, this.destination});
  final String? q, destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasQuery = (q != null && q!.trim().isNotEmpty) || destination != null;
    if (!hasQuery) return const SizedBox.shrink();
    final ads =
        ref
            .watch(
              adsProvider(
                AdQuery(
                  'top_search',
                  destination: destination,
                  q: q?.trim(),
                  limit: 2,
                ),
              ),
            )
            .value ??
        const <Json>[];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        children: [
          for (final ad in ads)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SearchAd(ad),
            ),
        ],
      ),
    );
  }
}

class _SearchAd extends ConsumerWidget {
  const _SearchAd(this.ad);
  final Json ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = _text(context, ad, 'offer');
    return _Seen(
      id: ad['id'] as String,
      child: Pressable(
        onTap: () => openAd(context, ref, ad),
        radius: 18,
        scale: 0.985,
        semanticLabel:
            '${context.l10n.sponsored}: ${_text(context, ad, 'title')}',
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Tokens.tint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Tokens.primary.withValues(alpha: .18)),
          ),
          child: Row(
            children: [
              WImage(
                ad['image_url'] as String?,
                width: 76,
                height: 76,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SponsoredBadge(onImage: false),
                    const SizedBox(height: 5),
                    Text(
                      _text(context, ad, 'title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Type.body(15, weight: FontWeight.w800),
                    ),
                    Text(
                      offer.isNotEmpty ? offer : _text(context, ad, 'body'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Type.body(12.5, color: Tokens.inkMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Tokens.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ detail sheet and story page ------------------------------ */

class _AdSheet extends ConsumerWidget {
  const _AdSheet({required this.ad});
  final Json ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = (ad['business_phone'] as String?)?.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );
    final url = ad['cta_url'] as String?;
    final stay = ad['accommodation_slug'] as String?;
    final offer = _text(context, ad, 'offer');
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Tokens.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WImage(
                    ad['image_url'] as String?,
                    full: true,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  const Positioned(left: 12, top: 12, child: SponsoredBadge()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _text(context, ad, 'title'),
            style: Type.display(24, height: 1.15),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.l10n.adsPromotedBy} ${_business(context, ad)}',
            style: Type.body(
              13,
              color: Tokens.inkMuted,
              weight: FontWeight.w700,
            ),
          ),
          if (offer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Tokens.cta,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                offer,
                style: Type.body(
                  13.5,
                  color: Tokens.onCta,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (_text(context, ad, 'body').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _text(context, ad, 'body'),
              style: Type.body(15, color: Tokens.inkSoft, height: 1.5),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (stay != null)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/stays/$stay');
                  },
                  icon: const Icon(Icons.bed_outlined),
                  label: Text(context.l10n.adsViewStay),
                ),
              if (url != null && url.startsWith('https://'))
                FilledButton.icon(
                  onPressed: () => _open(url),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(context.l10n.adsVisit),
                ),
              if (phone != null && phone.length >= 6)
                OutlinedButton.icon(
                  onPressed: () => _open('tel:$phone'),
                  icon: const Icon(Icons.call_outlined),
                  label: Text(context.l10n.adsCall),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.adsPaidNote,
            style: Type.body(12, color: Tokens.inkMuted),
          ),
        ],
      ),
    );
  }
}

class SponsoredArticleScreen extends ConsumerWidget {
  const SponsoredArticleScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(sponsoredArticleProvider(id));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: res.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(sponsoredArticleProvider(id)),
        ),
        data: (a) {
          final url = a['cta_url'] as String?;
          final stay = a['accommodation_slug'] as String?;
          final phone = (a['business_phone'] as String?)?.replaceAll(
            RegExp(r'[^0-9+]'),
            '',
          );
          final paragraphs = _text(
            context,
            a,
            'article',
          ).split(RegExp(r'\n\s*\n'));
          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      WImage(
                        a['image_url'] as String?,
                        full: true,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      const Positioned(
                        left: 14,
                        top: 14,
                        child: SponsoredBadge(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _text(context, a, 'title'),
                style: Type.display(28, height: 1.15),
              ),
              const SizedBox(height: 6),
              Text(
                '${context.l10n.adsPromotedBy} ${_business(context, a)}',
                style: Type.body(
                  13.5,
                  color: Tokens.inkMuted,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              for (final p in paragraphs)
                if (p.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      p.trim(),
                      style: Type.body(16, color: Tokens.inkSoft, height: 1.65),
                    ),
                  ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (stay != null)
                    FilledButton.icon(
                      onPressed: () => context.push('/stays/$stay'),
                      icon: const Icon(Icons.bed_outlined),
                      label: Text(context.l10n.adsViewStay),
                    ),
                  if (url != null && url.startsWith('https://'))
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(adTrackerProvider).click(id);
                        _open(url);
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(context.l10n.adsVisit),
                    ),
                  if (phone != null && phone.length >= 6)
                    OutlinedButton.icon(
                      onPressed: () => _open('tel:$phone'),
                      icon: const Icon(Icons.call_outlined),
                      label: Text(context.l10n.adsCall),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.adsPaidNote,
                style: Type.body(12, color: Tokens.inkMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}
