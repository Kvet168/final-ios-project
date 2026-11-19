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
import '../auth/auth_controller.dart';
import '../maps/place_map.dart';

IconData amenityIcon(String code) => switch (code) {
  'wifi' => Icons.wifi_rounded,
  'pool' => Icons.pool_rounded,
  'ac' => Icons.ac_unit_rounded,
  'breakfast' => Icons.free_breakfast_outlined,
  'parking' => Icons.local_parking_rounded,
  'airport-shuttle' => Icons.airport_shuttle_outlined,
  'gym' => Icons.fitness_center_rounded,
  'spa' => Icons.spa_outlined,
  'restaurant' => Icons.restaurant_outlined,
  'family-room' => Icons.family_restroom_rounded,
  'kids-pool' => Icons.child_care_rounded,
  'accessible' => Icons.accessible_rounded,
  'bar' => Icons.local_bar_outlined,
  'laundry' => Icons.local_laundry_service_outlined,
  'kitchen' => Icons.kitchen_outlined,
  _ => Icons.check_circle_outline,
};

class StayDetailScreen extends ConsumerStatefulWidget {
  const StayDetailScreen({super.key, required this.slug, required this.params});
  final String slug;
  final Map<String, String> params;
  @override
  ConsumerState<StayDetailScreen> createState() => _StayDetailScreenState();
}

class _StayDetailScreenState extends ConsumerState<StayDetailScreen> {
  // Without dates in the link we pre-fill a two-night stay two weeks out so room prices are real, not blank.
  late String? ci =
      widget.params['checkIn'] ??
      iso(DateTime.now().add(const Duration(days: 14)));
  late String? co =
      widget.params['checkOut'] ??
      iso(DateTime.now().add(const Duration(days: 16)));
  late int rooms = int.tryParse(widget.params['rooms'] ?? '') ?? 1;
  late int adults = int.tryParse(widget.params['adults'] ?? '') ?? 2;
  late int children = int.tryParse(widget.params['children'] ?? '') ?? 0;
  bool recorded = false;
  int _img = 0;
  final _roomsKey = GlobalKey();

  /// Room the guest tapped; null means "cheapest bookable room".
  String? _roomId;

  /// The last loaded page. Changing rooms or dates reloads the quote, and showing this meanwhile keeps the scroll position.
  Json? _last;

  StayKey get key =>
      (slug: widget.slug, checkIn: ci, checkOut: co, rooms: rooms);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 119)),
      initialDateRange: ci != null && co != null
          ? DateTimeRange(start: DateTime.parse(ci!), end: DateTime.parse(co!))
          : null,
    );
    if (r != null) {
      setState(() {
        ci = iso(r.start);
        co = iso(r.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(stayDetailProvider(key));
    final fresh = res.value;
    if (fresh != null) _last = fresh;
    final shown = fresh ?? (res.isLoading ? _last : null);
    return StatusTone.light(
      child: Scaffold(
        body: shown != null
            ? Stack(
                children: [
                  _content(shown),
                  if (res.isLoading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                ],
              )
            : res.when(
                loading: () => Column(
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
                ),
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
                              ref.invalidate(stayDetailProvider(key)),
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

  Widget _content(Json a) {
    if (!recorded) {
      recorded = true;
      Future.microtask(
        () => ref
            .read(recentProvider.notifier)
            .add('stay', a['slug'] as String, a['name'] as String),
      );
    }
    final money = ref.watch(moneyProvider);
    final images = (a['images'] as List).cast<Json>();
    final amenities = (a['amenities'] as List).cast<Json>();
    final roomsList = (a['room_types'] as List).cast<Json>();
    final nights = nightsBetween(ci, co);
    final lat = (a['lat'] as num).toDouble(),
        lng = (a['lng'] as num).toDouble();
    final gallery = <String>{
      if (a['cover_image'] != null) a['cover_image'] as String,
      ...images.map((i) => i['url'] as String),
    }.toList();

    Widget policy(IconData i, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Tokens.tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(i, size: 20, color: Tokens.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Type.body(14, weight: FontWeight.w800)),
                const SizedBox(height: 2),
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

    bool bookable(Json r) {
      final q = r['quote'] as Json?;
      return q != null &&
          q['available'] == true &&
          adults <= (r['max_adults'] as int) * rooms &&
          children <= (r['max_children'] as int) * rooms;
    }

    Json? selected;
    for (final r in roomsList) {
      if (r['id'] == _roomId && bookable(r)) selected = r;
    }
    if (selected == null) {
      for (final r in roomsList.where(bookable)) {
        if (selected == null ||
            (r['quote']['total_usd'] as num) <
                (selected['quote']['total_usd'] as num)) {
          selected = r;
        }
      }
    }
    final selectedQuote = selected?['quote'] as Json?;

    void book() {
      final r = selected!;
      final qp = {
        'checkIn': ci!,
        'checkOut': co!,
        'rooms': '$rooms',
        'adults': '$adults',
        'children': '$children',
        'stay': a['slug'] as String,
      };
      context.push(
        Uri(path: '/book/${r['id']}', queryParameters: qp).toString(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 360,
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
                        context.canPop() ? context.pop() : context.go('/stays'),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 16,
                      top: 8,
                      bottom: 8,
                    ),
                    child: SaveHeart(
                      kind: 'accommodation',
                      id: a['id'] as String,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      gallery.isEmpty
                          ? WImage(
                              null,
                              height: double.infinity,
                              width: double.infinity,
                              fallbackIcon: Icons.hotel_outlined,
                            )
                          : PageView.builder(
                              itemCount: gallery.length,
                              onPageChanged: (i) => setState(() => _img = i),
                              itemBuilder: (_, i) => WImage(
                                gallery[i],
                                full: true,
                                width: double.infinity,
                                height: double.infinity,
                                label: context.l10n.photoNofM(
                                  i + 1,
                                  gallery.length,
                                  '${a['name']}',
                                ),
                                fallbackIcon: Icons.hotel_outlined,
                              ),
                            ),
                      const Scrim(top: true, strength: 0.3),
                      if (gallery.length > 1)
                        Positioned(
                          bottom: 44,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < gallery.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2.5,
                                  ),
                                  width: i == _img ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _img
                                        ? Colors.white
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
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StarRow(a['stars'] as int),
                          const SizedBox(width: 8),
                          Text(
                            stayTypeLabel(
                              context.l10n,
                              a['type'] as String?,
                            ).toUpperCase(),
                            style: Type.label(11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        a['name'] as String,
                        style: Type.display(34, height: 1.05),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 17,
                            color: Tokens.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${a['address']}',
                              style: Type.body(13.5, color: Tokens.inkMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RatingBadge(
                        rating: (a['rating_avg'] ?? 0) as num,
                        count: (a['review_count'] ?? 0) as int,
                      ),
                      if (a['data_notice'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Tokens.promo,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              a['data_notice'] as String,
                              style: Type.body(12.5, height: 1.5),
                            ),
                          ),
                        ),
                      if (a['image_credit'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            a['image_credit'] as String,
                            style: Type.body(12, color: Tokens.inkMuted),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        a['description'] as String,
                        style: Type.body(
                          15.5,
                          height: 1.65,
                          color: Tokens.inkSoft,
                        ),
                      ),
                      SectionHeader(context.l10n.whatThisPlaceOffers),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final m in amenities)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Tokens.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Tokens.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    amenityIcon(m['code'] as String),
                                    size: 18,
                                    color: Tokens.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    amenityLabel(
                                      context.l10n,
                                      m['code'] as String?,
                                      m['label'] as String,
                                    ),
                                    style: Type.body(
                                      13,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SectionHeader(context.l10n.goodToKnow),
                      policy(
                        Icons.event_available_outlined,
                        context.l10n.cancellation,
                        a['cancellation_policy'] as String,
                      ),
                      policy(
                        Icons.login_rounded,
                        context.l10n.checkIn,
                        context.l10n.fromTime('${a['check_in_from']}'),
                      ),
                      policy(
                        Icons.logout_rounded,
                        context.l10n.checkOut,
                        context.l10n.byTime('${a['check_out_until']}'),
                      ),
                      policy(
                        Icons.receipt_long_outlined,
                        context.l10n.taxesAndFees,
                        context.l10n.taxesAndFeesBody(
                          ((a['tax_rate'] as num) * 100).toStringAsFixed(0),
                          ((a['service_fee_rate'] as num) * 100)
                              .toStringAsFixed(0),
                        ),
                      ),
                      SectionHeader(context.l10n.location),
                      PlaceMap(
                        height: 220,
                        radius: 24,
                        points: [
                          MapPoint(
                            lat: lat,
                            lng: lng,
                            title: a['name'] as String,
                            subtitle: a['address'] as String?,
                            kind: 'stay',
                          ),
                        ],
                      ),
                      Container(
                        key: _roomsKey,
                        child: SectionHeader(context.l10n.chooseYourRoom),
                      ),
                      _DateCard(
                        ci: ci,
                        co: co,
                        nights: nights,
                        adults: adults,
                        children: children,
                        rooms: rooms,
                        onDates: _pickDates,
                        onRooms: (v) => setState(() => rooms = v),
                      ),
                      const SizedBox(height: 14),
                      for (final (ri, r) in roomsList.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _RoomCard(
                            room: r,
                            image:
                                (r['cover_image'] as String?) ??
                                (gallery.isEmpty
                                    ? null
                                    : gallery[ri % gallery.length]),
                            money: money,
                            nights: nights,
                            guestsFit:
                                adults <= (r['max_adults'] as int) * rooms &&
                                children <= (r['max_children'] as int) * rooms,
                            selected:
                                selected != null && selected['id'] == r['id'],
                            onSelect: () =>
                                setState(() => _roomId = r['id'] as String),
                            onNeedDates: _pickDates,
                          ),
                        ),
                      _Reviews(slug: a['slug'] as String),
                      if ((a['related'] as List).isNotEmpty) ...[
                        SectionHeader(context.l10n.similarStays),
                      ],
                    ],
                  ),
                ),
              ),
              if ((a['related'] as List).isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 372,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: (a['related'] as List).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (_, i) {
                        final r = (a['related'] as List).cast<Json>()[i];
                        return StayCard(
                          {
                            ...r,
                            'price_from': r['from_price_usd'],
                            'destination_name': a['destination_name'],
                          },
                          compact: true,
                          width: 272,
                        );
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            16,
            10 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: Tokens.surface,
            border: Border(top: BorderSide(color: Tokens.border)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedQuote != null) ...[
                      Text(
                        money(selectedQuote['total_usd'] as num),
                        style: Type.display(26, height: 1.1),
                      ),
                      Text(
                        context.l10n.totalForStay(nights),
                        style: Type.body(12.5, color: Tokens.inkMuted),
                      ),
                    ] else
                      Text(
                        context.l10n.selectARoomHint,
                        style: Type.body(13.5, color: Tokens.inkMuted),
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: selected == null ? null : book,
                style: FilledButton.styleFrom(minimumSize: const Size(150, 54)),
                child: Text(context.l10n.bookNow),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.ci,
    required this.co,
    required this.nights,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.onDates,
    required this.onRooms,
  });
  final String? ci, co;
  final int nights, adults, children, rooms;
  final VoidCallback onDates;
  final ValueChanged<int> onRooms;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Tokens.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Tokens.border),
    ),
    child: Column(
      children: [
        Pressable(
          onTap: onDates,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Tokens.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Tokens.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ci != null && co != null
                          ? '${fmtDate(ci)} → ${fmtDate(co)}'
                          : context.l10n.chooseYourDates,
                      style: Type.body(15, weight: FontWeight.w800),
                    ),
                    Text(
                      nights > 0
                          ? context.l10n.nightsTapToChange(nights)
                          : context.l10n.tapToSelect,
                      style: Type.body(12.5, color: Tokens.inkMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_outlined, color: Tokens.inkMuted),
            ],
          ),
        ),
        const Divider(height: 28),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Tokens.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Tokens.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.l10n.adultsCount(adults)}${children > 0 ? ', ${context.l10n.childrenCount(children)}' : ''}',
                    style: Type.body(15, weight: FontWeight.w800),
                  ),
                  Text(
                    context.l10n.roomsCount(rooms),
                    style: Type.body(12.5, color: Tokens.inkMuted),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: context.l10n.removeRoom,
              onPressed: rooms > 1 ? () => onRooms(rooms - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              tooltip: context.l10n.addRoom,
              onPressed: rooms < 6 ? () => onRooms(rooms + 1) : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.image,
    required this.money,
    required this.nights,
    required this.guestsFit,
    required this.selected,
    required this.onSelect,
    required this.onNeedDates,
  });
  final Json room;

  /// The room's own photo, or a photo of the property when the owner has not added one, so every room shows an image.
  final String? image;
  final String Function(num) money;
  final int nights;
  final bool guestsFit;
  final bool selected;
  final VoidCallback onSelect, onNeedDates;

  @override
  Widget build(BuildContext context) {
    final quote = room['quote'] as Json?;
    final available = quote?['available'] == true;
    final reason = quote?['reason'] as String?;
    final canSelect = quote != null && guestsFit && available;
    Widget? status;
    if (quote == null) {
      status = OutlinedButton(
        onPressed: onNeedDates,
        child: Text(context.l10n.selectDates),
      );
    } else if (!guestsFit) {
      status = Pill(context.l10n.tooSmallForParty, color: Tokens.danger);
    } else if (!available) {
      status = Pill(context.l10n.notAvailable, color: Tokens.danger);
    }
    Widget meta(IconData i, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 16, color: Tokens.primary),
        const SizedBox(width: 5),
        Text(
          t,
          style: Type.body(
            12.5,
            color: Tokens.inkSoft,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canSelect ? onSelect : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? Tokens.primary : Tokens.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: Tokens.softShadow(0.06),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WImage(
                      image,
                      full: true,
                      width: double.infinity,
                      height: double.infinity,
                      label: room['name'] as String,
                      fallbackIcon: Icons.bed_outlined,
                    ),
                    if (selected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Tokens.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.selectedLabel,
                                style: Type.body(
                                  12,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    room['name'] as String,
                    style: Type.display(22, height: 1.1),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(room['base_price_usd'] as num),
                      style: Type.display(22, height: 1.1),
                    ),
                    Text(
                      context.l10n.basePerNight,
                      style: Type.body(12, color: Tokens.inkMuted),
                    ),
                    if (quote != null && canSelect) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${money(quote['total_usd'] as num)} ${context.l10n.totalForStay(nights)}',
                        style: Type.body(
                          12,
                          weight: FontWeight.w700,
                          color: Tokens.primaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              room['description'] as String,
              style: Type.body(13.5, color: Tokens.inkMuted, height: 1.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                meta(Icons.bed_outlined, room['bed_type'] as String),
                meta(
                  Icons.people_outline,
                  '${context.l10n.upToAdults(room['max_adults'] as int)}${(room['max_children'] as int) > 0 ? context.l10n.plusChildren(room['max_children'] as int) : ''}',
                ),
                if (room['size_sqm'] != null)
                  meta(Icons.square_foot_rounded, '${room['size_sqm']} m²'),
                if (room['breakfast_included'] == true)
                  meta(
                    Icons.free_breakfast_outlined,
                    context.l10n.breakfastIncluded,
                  ),
              ],
            ),
            if (quote != null && !available && reason != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(reason, style: Type.body(13, color: Tokens.danger)),
              ),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Align(alignment: Alignment.centerRight, child: status),
              ),
          ],
        ),
      ),
    );
  }
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(reviewsProvider(slug));
    final signedIn = ref.watch(authProvider).signedIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          context.l10n.guestReviews,
          action: context.l10n.writeOne,
          onAction: () {
            if (!signedIn) {
              context.push(
                '/login?next=${Uri.encodeComponent(GoRouterState.of(context).uri.toString())}',
              );
            } else {
              _write(context, ref);
            }
          },
        ),
        AsyncView<Json>(
          value: res,
          onRetry: () => ref.invalidate(reviewsProvider(slug)),
          data: (r) {
            final items = (r['items'] as List).cast<Json>();
            if (items.isEmpty) {
              return EmptyState(
                title: context.l10n.noReviewsYet,
                message: context.l10n.beFirstReview,
                icon: Icons.rate_review_outlined,
              );
            }
            return Column(
              children: [
                for (final v in items)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Tokens.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Tokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Tokens.tint,
                              child: Text(
                                ((v['author'] as String?) ?? '?').substring(
                                  0,
                                  1,
                                ),
                                style: Type.body(
                                  15,
                                  weight: FontWeight.w800,
                                  color: Tokens.primaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${v['author']}',
                                    style: Type.body(
                                      14,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    fmtDate(
                                      v['created_at'] as String?,
                                      pattern: 'MMM y',
                                    ),
                                    style: Type.body(
                                      11.5,
                                      color: Tokens.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < (v['rating'] as int); i++)
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Tokens.star,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          v['title'] as String,
                          style: Type.body(15, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v['body'] as String,
                          style: Type.body(
                            14,
                            height: 1.55,
                            color: Tokens.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (v['verified_stay'] == true)
                          Pill(
                            context.l10n.verifiedStay,
                            icon: Icons.verified_outlined,
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _write(BuildContext context, WidgetRef ref) async {
    var rating = 5;
    final title = TextEditingController();
    final body = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(context.l10n.writeAReview),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          tooltip: context.l10n.starsCount(i),
                          onPressed: () => set(() => rating = i),
                          icon: Icon(
                            i <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Tokens.star,
                          ),
                        ),
                    ],
                  ),
                  TextFormField(
                    controller: title,
                    decoration: InputDecoration(labelText: context.l10n.title),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? context.l10n.addShortTitle
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: body,
                    decoration: InputDecoration(
                      labelText: context.l10n.yourExperience,
                    ),
                    maxLines: 4,
                    validator: (v) => (v ?? '').trim().length < 10
                        ? context.l10n.atLeast10Chars
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.onlyGuestsCanReview,
                    style: Type.body(12, color: Tokens.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref
                      .read(apiProvider)
                      .postJson(
                        '/accommodations/$slug/reviews',
                        body: {
                          'rating': rating,
                          'title': title.text.trim(),
                          'body': body.text.trim(),
                        },
                      );
                  ref.invalidate(reviewsProvider(slug));
                  if (c.mounted) Navigator.pop(c);
                } catch (e) {
                  if (c.mounted) showError(c, e);
                }
              },
              child: Text(context.l10n.submit),
            ),
          ],
        ),
      ),
    );
  }
}
