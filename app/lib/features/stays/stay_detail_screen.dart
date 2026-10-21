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
  late String? ci = widget.params['checkIn'] ?? iso(DateTime.now().add(const Duration(days: 14)));
  late String? co = widget.params['checkOut'] ?? iso(DateTime.now().add(const Duration(days: 16)));
  late int rooms = int.tryParse(widget.params['rooms'] ?? '') ?? 1;
  late int adults = int.tryParse(widget.params['adults'] ?? '') ?? 2;
  late int children = int.tryParse(widget.params['children'] ?? '') ?? 0;
  bool recorded = false;
  int _img = 0;
  final _roomsKey = GlobalKey();

  StayKey get key => (slug: widget.slug, checkIn: ci, checkOut: co, rooms: rooms);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 119)),
      initialDateRange: ci != null && co != null ? DateTimeRange(start: DateTime.parse(ci!), end: DateTime.parse(co!)) : null,
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
    return StatusTone.light(child: Scaffold(
      body: res.when(
        loading: () => Column(children: [Container(height: 380, decoration: const BoxDecoration(gradient: Tokens.dusk)), const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 3, itemHeight: 90))]),
        error: (e, _) => SafeArea(child: Column(children: [Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.all(8), child: BackButton(onPressed: () => context.pop()))), Expanded(child: ErrorState(error: e, onRetry: () => ref.invalidate(stayDetailProvider(key))))])),
        data: _content,
      ),
    ));
  }

  Widget _content(Json a) {
    if (!recorded) {
      recorded = true;
      Future.microtask(() => ref.read(recentProvider.notifier).add('stay', a['slug'] as String, a['name'] as String));
    }
    final money = ref.watch(moneyProvider);
    final images = (a['images'] as List).cast<Json>();
    final amenities = (a['amenities'] as List).cast<Json>();
    final roomsList = (a['room_types'] as List).cast<Json>();
    final nights = nightsBetween(ci, co);
    final lat = (a['lat'] as num).toDouble(), lng = (a['lng'] as num).toDouble();
    final gallery = <String>{if (a['cover_image'] != null) a['cover_image'] as String, ...images.map((i) => i['url'] as String)}.toList();

    Widget policy(IconData i, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Tokens.mint, borderRadius: BorderRadius.circular(13)), child: Icon(i, size: 20, color: Tokens.forest)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Type.body(14, weight: FontWeight.w800)), const SizedBox(height: 2), Text(body, style: Type.body(13.5, color: Tokens.inkSoft, height: 1.5))])),
          ]),
        );

    final from = roomsList.isEmpty ? (a['from_price_usd'] as num) : roomsList.map((r) => r['base_price_usd'] as num).reduce((x, y) => x < y ? x : y);

    return Stack(children: [
      CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: 360,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          automaticallyImplyLeading: false,
          backgroundColor: Tokens.forestDeep,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          leading: Padding(padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8), child: GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onTap: () => context.canPop() ? context.pop() : context.go('/stays'))),
          actions: [Padding(padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8), child: SaveHeart(kind: 'accommodation', id: a['id'] as String))],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(fit: StackFit.expand, children: [
              gallery.isEmpty
                  ? WImage(null, height: double.infinity, width: double.infinity, fallbackIcon: Icons.hotel_outlined)
                  : PageView.builder(
                      itemCount: gallery.length,
                      onPageChanged: (i) => setState(() => _img = i),
                      itemBuilder: (_, i) => WImage(gallery[i], full: true, width: double.infinity, height: double.infinity, label: 'Photo ${i + 1} of ${gallery.length} for ${a['name']}', fallbackIcon: Icons.hotel_outlined),
                    ),
              const Scrim(top: true, strength: 0.3),
              if (gallery.length > 1)
                Positioned(
                  bottom: 44,
                  left: 0,
                  right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < gallery.length; i++)
                      AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 2.5), width: i == _img ? 18 : 6, height: 6, decoration: BoxDecoration(color: i == _img ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(6))),
                  ]),
                ),
            ]),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: Container(height: 28, decoration: const BoxDecoration(color: Tokens.ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(32)))),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                StarRow(a['stars'] as int),
                const SizedBox(width: 8),
                Text(typeLabel(a['type'] as String?).toUpperCase(), style: Type.label(11)),
                const SizedBox(width: 8),
                if (a['is_demo'] == true) const DemoBadge(),
              ]),
              const SizedBox(height: 10),
              Text(a['name'] as String, style: Type.display(34, height: 1.05)),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.place_outlined, size: 17, color: Tokens.inkMuted),
                const SizedBox(width: 4),
                Expanded(child: Text('${a['address']}', style: Type.body(13.5, color: Tokens.inkMuted))),
              ]),
              const SizedBox(height: 12),
              RatingBadge(rating: (a['rating_avg'] ?? 0) as num, count: (a['review_count'] ?? 0) as int),
              if (a['data_notice'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Tokens.gold.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)), child: Text(a['data_notice'] as String, style: Type.body(12.5, height: 1.5))),
                ),
              if (a['image_credit'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(a['image_credit'] as String, style: Type.body(10.5, color: Tokens.inkMuted))),
              const SizedBox(height: 18),
              Text(a['description'] as String, style: Type.body(15.5, height: 1.65, color: Tokens.inkSoft)),
              const SectionHeader('What this place offers'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final m in amenities)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: Tokens.border)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(amenityIcon(m['code'] as String), size: 18, color: Tokens.forest), const SizedBox(width: 8), Text(m['label'] as String, style: Type.body(13, weight: FontWeight.w600))]),
                  ),
              ]),
              const SectionHeader('Good to know'),
              policy(Icons.event_available_outlined, 'Cancellation', a['cancellation_policy'] as String),
              policy(Icons.login_rounded, 'Check-in', 'From ${a['check_in_from']}'),
              policy(Icons.logout_rounded, 'Check-out', 'By ${a['check_out_until']}'),
              policy(Icons.receipt_long_outlined, 'Taxes and fees', '${((a['tax_rate'] as num) * 100).toStringAsFixed(0)}% tax and ${((a['service_fee_rate'] as num) * 100).toStringAsFixed(0)}% service fee are added to the room rate and shown before you pay.'),
              const SectionHeader('Location'),
              PlaceMap(height: 220, radius: 24, points: [MapPoint(lat: lat, lng: lng, title: a['name'] as String, subtitle: a['address'] as String?, kind: 'stay')]),
              Container(key: _roomsKey, child: const SectionHeader('Choose your room')),
              _DateCard(ci: ci, co: co, nights: nights, adults: adults, children: children, rooms: rooms, onDates: _pickDates, onRooms: (v) => setState(() => rooms = v)),
              const SizedBox(height: 14),
              for (final r in roomsList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _RoomCard(
                    room: r,
                    money: money,
                    nights: nights,
                    guestsFit: adults <= (r['max_adults'] as int) * rooms && children <= (r['max_children'] as int) * rooms,
                    onReserve: () {
                      final qp = {'checkIn': ci!, 'checkOut': co!, 'rooms': '$rooms', 'adults': '$adults', 'children': '$children', 'stay': a['slug'] as String};
                      context.push(Uri(path: '/book/${r['id']}', queryParameters: qp).toString());
                    },
                    onNeedDates: _pickDates,
                  ),
                ),
              _Reviews(slug: a['slug'] as String),
              if ((a['related'] as List).isNotEmpty) ...[
                const SectionHeader('Similar stays nearby'),
              ],
            ]),
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
                  return StayCard({...r, 'price_from': r['from_price_usd'], 'destination_name': a['destination_name']}, compact: true, width: 272);
                },
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 130 + MediaQuery.paddingOf(context).bottom)),
      ]),
      Positioned(
        left: 16,
        right: 16,
        bottom: 12 + MediaQuery.paddingOf(context).bottom,
        child: Glass(
          radius: 26,
          blur: 22,
          tint: const Color(0xE6FFFFFF),
          border: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('FROM', style: Type.label(10)),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(money(from), style: Type.display(26, height: 1.1)), Padding(padding: const EdgeInsets.only(bottom: 3, left: 4), child: Text('/ night', style: Type.body(12.5, color: Tokens.inkMuted)))]),
              ]),
            ),
            FilledButton(
              onPressed: () => Scrollable.ensureVisible(_roomsKey.currentContext!, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic),
              style: FilledButton.styleFrom(minimumSize: const Size(150, 54)),
              child: const Text('Choose a room'),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.ci, required this.co, required this.nights, required this.adults, required this.children, required this.rooms, required this.onDates, required this.onRooms});
  final String? ci, co;
  final int nights, adults, children, rooms;
  final VoidCallback onDates;
  final ValueChanged<int> onRooms;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(22), border: Border.all(color: Tokens.border)),
        child: Column(children: [
          Pressable(
            onTap: onDates,
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Tokens.forest.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.calendar_month_rounded, color: Tokens.forest)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ci != null && co != null ? '${fmtDate(ci)} → ${fmtDate(co)}' : 'Choose your dates', style: Type.body(15, weight: FontWeight.w800)),
                  Text(nights > 0 ? '$nights night${nights == 1 ? '' : 's'} · tap to change' : 'Tap to select', style: Type.body(12.5, color: Tokens.inkMuted)),
                ]),
              ),
              const Icon(Icons.edit_calendar_outlined, color: Tokens.inkMuted),
            ]),
          ),
          const Divider(height: 28),
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Tokens.forest.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.people_alt_rounded, color: Tokens.forest)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$adults adult${adults > 1 ? 's' : ''}${children > 0 ? ', $children child${children > 1 ? 'ren' : ''}' : ''}', style: Type.body(15, weight: FontWeight.w800)),
                Text('$rooms room${rooms > 1 ? 's' : ''}', style: Type.body(12.5, color: Tokens.inkMuted)),
              ]),
            ),
            IconButton.outlined(tooltip: 'Remove a room', onPressed: rooms > 1 ? () => onRooms(rooms - 1) : null, icon: const Icon(Icons.remove_rounded)),
            const SizedBox(width: 6),
            IconButton.outlined(tooltip: 'Add a room', onPressed: rooms < 6 ? () => onRooms(rooms + 1) : null, icon: const Icon(Icons.add_rounded)),
          ]),
        ]),
      );
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.money, required this.nights, required this.guestsFit, required this.onReserve, required this.onNeedDates});
  final Json room;
  final String Function(num) money;
  final int nights;
  final bool guestsFit;
  final VoidCallback onReserve, onNeedDates;

  @override
  Widget build(BuildContext context) {
    final quote = room['quote'] as Json?;
    final available = quote?['available'] == true;
    final reason = quote?['reason'] as String?;
    Widget action;
    if (quote == null) {
      action = OutlinedButton(onPressed: onNeedDates, child: const Text('Select dates'));
    } else if (!guestsFit) {
      action = const Pill('Too small for your party', color: Tokens.danger);
    } else if (!available) {
      action = const Pill('Not available', color: Tokens.danger);
    } else {
      action = FilledButton.icon(onPressed: onReserve, icon: const Icon(Icons.lock_outline_rounded, size: 18), label: const Text('Reserve'), style: FilledButton.styleFrom(minimumSize: const Size(140, 50)));
    }
    Widget meta(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 16, color: Tokens.jade), const SizedBox(width: 5), Text(t, style: Type.body(12.5, color: Tokens.inkSoft, weight: FontWeight.w600))]);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(24), border: Border.all(color: Tokens.border), boxShadow: Tokens.softShadow(0.06)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(room['name'] as String, style: Type.display(22, height: 1.1))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(money(room['base_price_usd'] as num), style: Type.display(22, height: 1.1)), Text('base / night', style: Type.body(11.5, color: Tokens.inkMuted))]),
        ]),
        const SizedBox(height: 6),
        Text(room['description'] as String, style: Type.body(13.5, color: Tokens.inkMuted, height: 1.5)),
        const SizedBox(height: 12),
        Wrap(spacing: 14, runSpacing: 6, children: [
          meta(Icons.bed_outlined, room['bed_type'] as String),
          meta(Icons.people_outline, 'Up to ${room['max_adults']} adults${(room['max_children'] as int) > 0 ? ' + ${room['max_children']} ${room['max_children'] == 1 ? 'child' : 'children'}' : ''}'),
          if (room['size_sqm'] != null) meta(Icons.square_foot_rounded, '${room['size_sqm']} m²'),
          if (room['breakfast_included'] == true) meta(Icons.free_breakfast_outlined, 'Breakfast included'),
        ]),
        if (quote != null && available && guestsFit) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: DashedLine()),
          PriceRow('${money((quote['subtotal_usd'] as num) / (quote['rooms'] as int) / (quote['nights'] as int))} avg × ${quote['nights']} night${quote['nights'] == 1 ? '' : 's'}${(quote['rooms'] as int) > 1 ? ' × ${quote['rooms']} rooms' : ''}', money(quote['subtotal_usd'] as num)),
          PriceRow('Taxes (${((quote['tax_rate'] as num) * 100).toStringAsFixed(0)}%)', money(quote['taxes_usd'] as num), muted: true),
          PriceRow('Service fee (${((quote['service_fee_rate'] as num) * 100).toStringAsFixed(0)}%)', money(quote['fees_usd'] as num), muted: true),
          PriceRow('Total', money(quote['total_usd'] as num), bold: true),
        ],
        if (quote != null && !available && reason != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(reason, style: Type.body(13, color: Tokens.danger))),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: action),
      ]),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('Guest reviews', subtitle: 'Sample data in this demo', action: 'Write one', onAction: () {
        if (!signedIn) {
          context.push('/login?next=${Uri.encodeComponent(GoRouterState.of(context).uri.toString())}');
        } else {
          _write(context, ref);
        }
      }),
      AsyncView<Json>(
        value: res,
        onRetry: () => ref.invalidate(reviewsProvider(slug)),
        data: (r) {
          final items = (r['items'] as List).cast<Json>();
          if (items.isEmpty) return const EmptyState(title: 'No reviews yet', message: 'Be the first to share your stay.', icon: Icons.rate_review_outlined);
          return Column(children: [
            for (final v in items)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(20), border: Border.all(color: Tokens.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: Tokens.mint, child: Text(((v['author'] as String?) ?? '?').substring(0, 1), style: Type.body(15, weight: FontWeight.w800, color: Tokens.forest))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${v['author']}', style: Type.body(14, weight: FontWeight.w800)), Text(fmtDate(v['created_at'] as String?, pattern: 'MMM y'), style: Type.body(11.5, color: Tokens.inkMuted))])),
                    Row(children: [for (var i = 0; i < (v['rating'] as int); i++) const Icon(Icons.star_rounded, size: 16, color: Tokens.gold)]),
                  ]),
                  const SizedBox(height: 12),
                  Text(v['title'] as String, style: Type.body(15, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(v['body'] as String, style: Type.body(14, height: 1.55, color: Tokens.inkSoft)),
                  const SizedBox(height: 10),
                  if (v['is_demo'] == true) const DemoBadge(text: 'Demo review') else if (v['verified_stay'] == true) const Pill('Verified stay', icon: Icons.verified_outlined),
                ]),
              ),
          ]);
        },
      ),
    ]);
  }

  Future<void> _write(BuildContext context, WidgetRef ref) async {
    var rating = 5;
    final title = TextEditingController();
    final body = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, set) => AlertDialog(
        title: const Text('Write a review'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [for (var i = 1; i <= 5; i++) IconButton(tooltip: '$i star${i > 1 ? 's' : ''}', onPressed: () => set(() => rating = i), icon: Icon(i <= rating ? Icons.star_rounded : Icons.star_border_rounded, color: Tokens.gold))]),
              TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => (v ?? '').trim().length < 3 ? 'Add a short title' : null),
              const SizedBox(height: 12),
              TextFormField(controller: body, decoration: const InputDecoration(labelText: 'Your experience'), maxLines: 4, validator: (v) => (v ?? '').trim().length < 10 ? 'Please write at least 10 characters' : null),
              const SizedBox(height: 8),
              Text('Only guests with a confirmed booking can review a property.', style: Type.body(12, color: Tokens.inkMuted)),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref.read(apiProvider).postJson('/accommodations/$slug/reviews', body: {'rating': rating, 'title': title.text.trim(), 'body': body.text.trim()});
                ref.invalidate(reviewsProvider(slug));
                if (c.mounted) Navigator.pop(c);
              } catch (e) {
                if (c.mounted) showError(c, e);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      )),
    );
  }
}
