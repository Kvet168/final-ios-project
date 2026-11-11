import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});
  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  bool past = false;

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(bookingsProvider);
    final money = ref.watch(moneyProvider);
    final today = iso(DateTime.now());
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(bookingsProvider.future),
        child: CustomScrollView(
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
                title: Text(context.l10n.myBookings, style: Type.display(26)),
              ),
            ),
            SliverToBoxAdapter(
              child: res.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: SkeletonList(count: 3, itemHeight: 150),
                ),
                error: (e, _) => ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(bookingsProvider),
                ),
                data: (r) {
                  final all = (r['items'] as List).cast<Json>();
                  if (all.isEmpty) {
                    return EmptyState(
                      icon: Icons.luggage_outlined,
                      title: 'No bookings yet',
                      message: 'When you book a stay it will appear here as a ticket.',
                      action: FilledButton(
                        onPressed: () => context.go('/stays'),
                        child: const Text('Find a stay'),
                      ),
                    );
                  }
                  bool isPast(Json b) =>
                      (b['check_out'] as String).compareTo(today) < 0 ||
                      [
                        'CANCELLED',
                        'EXPIRED',
                        'REFUNDED',
                        'COMPLETED',
                      ].contains(b['status']);
                  final items = all.where((b) => isPast(b) == past).toList();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            WChip(
                              context.l10n.upcoming,
                              selected: !past,
                              count: all.where((b) => !isPast(b)).length,
                              onTap: () => setState(() => past = false),
                            ),
                            const SizedBox(width: 8),
                            WChip(
                              context.l10n.pastAndCancelled,
                              selected: past,
                              count: all.where(isPast).length,
                              onTap: () => setState(() => past = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (items.isEmpty)
                          EmptyState(
                            icon: Icons.confirmation_number_outlined,
                            title: past
                                ? context.l10n.nothingHereYet
                                : context.l10n.noUpcomingTrips,
                            message: past
                                ? context.l10n.pastBookingsHint
                                : context.l10n.nextAdventureHint,
                          ),
                        for (final (i, b) in items.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Reveal(
                              delay: Duration(milliseconds: 60 * i),
                              child: _TicketCard(b: b, money: money),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.b, required this.money});
  final Json b;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) {
    final nights = b['nights'] as int;
    return Pressable(
      onTap: () => context.push('/bookings/${b['id']}'),
      child: Container(
        decoration: BoxDecoration(boxShadow: Tokens.softShadow(0.10)),
        child: ClipPath(
          clipper: const TicketShape(notchY: 0.64, radius: 24),
          child: Container(
            color: Tokens.surface,
            child: Column(
              children: [
                SizedBox(
                  height: 122,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      WImage(
                        b['cover_image'] as String?,
                        width: double.infinity,
                        height: double.infinity,
                        fallbackIcon: Icons.hotel_outlined,
                      ),
                      const Scrim(top: true, strength: 0.85),
                      Positioned(
                        left: 18,
                        top: 14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .95),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: StatusPill(b['status'] as String),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 12,
                        child: Text(
                          b['accommodation_name'] as String,
                          style: Type.display(
                            21,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _field(
                          context.l10n.checkIn.toUpperCase(),
                          fmtDate(
                            b['check_in'] as String,
                            pattern: 'EEE d MMM',
                          ),
                        ),
                      ),
                      Expanded(
                        child: _field(
                          context.l10n.checkOut.toUpperCase(),
                          fmtDate(
                            b['check_out'] as String,
                            pattern: 'EEE d MMM',
                          ),
                        ),
                      ),
                      _field(
                        context.l10n.nights.toUpperCase(),
                        '$nights',
                        end: true,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: DashedLine(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.reference.toUpperCase(),
                              style: Type.label(11),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              b['reference'] as String,
                              style: Type.body(
                                13,
                                weight: FontWeight.w800,
                                spacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money(b['total_usd'] as num),
                        style: Type.display(22),
                      ),
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

  Widget _field(String l, String v, {bool end = false}) => Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(l, style: Type.label(11)),
      const SizedBox(height: 3),
      Text(v, style: Type.body(14, weight: FontWeight.w800)),
    ],
  );
}

/// Decorative pseudo-code on the ticket stub. It encodes nothing; the booking reference is the real identifier.
class _StubPainter extends CustomPainter {
  _StubPainter(this.seed);
  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed.hashCode);
    final p = Paint()..color = Tokens.ink;
    var x = 0.0;
    while (x < size.width) {
      final w = 1.0 + rnd.nextInt(4) * 1.2;
      if (rnd.nextBool()) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), p);
      }
      x += w + 1.2;
    }
  }

  @override
  bool shouldRepaint(covariant _StubPainter old) => old.seed != seed;
}

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.id,
    this.justPaid = false,
  });
  final String id;
  final bool justPaid;
  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool busy = false;

  Future<void> _cancel(Json b) async {
    final free = b['freeCancellation'] == true;
    final paid = (b['payments'] as List).any((p) => p['status'] == 'SUCCESS');
    final ok = await confirm(
      context,
      title: context.l10n.cancelBookingQ,
      message: free
          ? (paid
                ? context.l10n.cancelFreePaidBody
                : context.l10n.cancelFreeBody)
          : context.l10n.cancelNonRefundBody,
      confirmLabel: context.l10n.cancelBooking,
      destructive: true,
    );
    if (!ok) return;
    setState(() => busy = true);
    try {
      await ref.read(apiProvider).postJson('/bookings/${widget.id}/cancel');
      ref.invalidate(bookingDetailProvider(widget.id));
      ref.invalidate(bookingsProvider);
      if (mounted) showInfo(context, context.l10n.bookingCancelled);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _receipt() async {
    try {
      final r = await ref
          .read(apiProvider)
          .getJson('/bookings/${widget.id}/receipt');
      if (!mounted) return;
      final money = ref.read(moneyProvider);
      await showModalBottomSheet<void>(
        useRootNavigator:
            true, // cover the bottom bar instead of sliding under it
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.receiptCaps,
                style: Type.label(11, color: Tokens.primaryText),
              ),
              const SizedBox(height: 6),
              Text('${r['receiptNumber']}', style: Type.display(28)),
              const SizedBox(height: 14),
              if (r['notice'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Tokens.promo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    r['notice'] as String,
                    style: Type.body(13, weight: FontWeight.w700),
                  ),
                ),
              Text(
                '${r['property']} · ${r['room']}',
                style: Type.body(15, weight: FontWeight.w700),
              ),
              Text(
                '${fmtDate(r['checkIn'] as String)} → ${fmtDate(r['checkOut'] as String)}',
                style: Type.body(13.5, color: Tokens.inkMuted),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: DashedLine(),
              ),
              for (final l in (r['lineItems'] as List).cast<Json>())
                PriceRow(
                  l['label'] as String,
                  money(l['amountUsd'] as num),
                  muted: true,
                ),
              const Divider(height: 24),
              PriceRow(
                context.l10n.total,
                money(r['totalUsd'] as num),
                bold: true,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.paymentRefStatus(
                  '${r['paymentReference']}',
                  statusLabel(context.l10n, '${r['paymentStatus']}'),
                ),
                style: Type.body(12, color: Tokens.inkMuted),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(bookingDetailProvider(widget.id));
    final money = ref.watch(moneyProvider);
    return Scaffold(
      body: res.when(
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SkeletonList(count: 2, itemHeight: 260),
          ),
        ),
        error: (e, _) => SafeArea(
          child: ErrorState(
            error: e,
            onRetry: () => ref.invalidate(bookingDetailProvider(widget.id)),
          ),
        ),
        data: (b) {
          final status = b['status'] as String;
          final events = (b['events'] as List).cast<Json>();
          final payments = (b['payments'] as List).cast<Json>();
          final hasPaid = payments.any(
            (p) => ['SUCCESS', 'REFUNDED'].contains(p['status']),
          );
          final nights = b['nights'] as int;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to bookings',
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/bookings'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.yourBooking,
                        style: Type.display(26),
                      ),
                    ),
                  ],
                ),
                if (widget.justPaid && status == 'CONFIRMED')
                  const _Confirmed(),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(boxShadow: Tokens.softShadow(0.14)),
                  child: ClipPath(
                    clipper: const TicketShape(notchY: 0.66),
                    child: Container(
                      color: Tokens.surface,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 170,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                WImage(
                                  b['cover_image'] as String?,
                                  full: true,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fallbackIcon: Icons.hotel_outlined,
                                ),
                                const Scrim(top: true, strength: 0.9),
                                Positioned(
                                  left: 22,
                                  top: 18,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .95,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: StatusPill(status),
                                  ),
                                ),
                                Positioned(
                                  left: 22,
                                  right: 22,
                                  bottom: 16,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${b['destination_name']}'
                                            .toUpperCase(),
                                        style: Type.label(
                                          10.5,
                                          color: Tokens.onDarkMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () => context.push(
                                          '/stays/${b['accommodation_slug']}',
                                        ),
                                        child: Text(
                                          b['accommodation_name'] as String,
                                          style: Type.display(
                                            26,
                                            color: Colors.white,
                                            height: 1.05,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _f(
                                        context.l10n.checkIn.toUpperCase(),
                                        fmtDate(
                                          b['check_in'] as String,
                                          pattern: 'EEE d MMM',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _f(
                                        context.l10n.checkOut.toUpperCase(),
                                        fmtDate(
                                          b['check_out'] as String,
                                          pattern: 'EEE d MMM',
                                        ),
                                      ),
                                    ),
                                    _f(
                                      context.l10n.nights.toUpperCase(),
                                      '$nights',
                                      end: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _f(
                                        context.l10n.room.toUpperCase(),
                                        b['room_name'] as String,
                                      ),
                                    ),
                                    Expanded(
                                      child: _f(
                                        context.l10n.guests.toUpperCase(),
                                        '${context.l10n.adultsCount(b['adults'] as int)}${(b['children'] as int) > 0 ? ' + ${b['children']}' : ''} · ${context.l10n.roomsCount(b['rooms'] as int)}',
                                        end: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(22, 18, 22, 0),
                            child: DashedLine(),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _f(
                                        context.l10n.guest.toUpperCase(),
                                        b['guest_name'] as String,
                                      ),
                                    ),
                                    _f(
                                      context.l10n.total.toUpperCase(),
                                      money(b['total_usd'] as num),
                                      end: true,
                                      big: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 46,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _StubPainter(
                                      b['reference'] as String,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${b['reference']}',
                                  style: Type.body(
                                    14,
                                    weight: FontWeight.w800,
                                    spacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (status == 'PENDING_CONFIRMATION')
                      FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => context.push(
                                '/book/${b['room_type_id']}?bookingId=${b['id']}',
                              ),
                        icon: const Icon(Icons.payment_rounded),
                        label: Text(context.l10n.payForBooking),
                      ),
                    if (hasPaid)
                      OutlinedButton.icon(
                        onPressed: _receipt,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(context.l10n.receipt),
                      ),
                    if (b['cancellable'] == true)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Tokens.danger,
                        ),
                        onPressed: busy ? null : () => _cancel(b),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(context.l10n.cancelBooking),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.priceBreakdown,
                        style: Type.body(15, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      PriceRow(
                        context.l10n.roomSubtotal,
                        money(b['subtotal_usd'] as num),
                      ),
                      PriceRow(
                        context.l10n.taxes,
                        money(b['taxes_usd'] as num),
                        muted: true,
                      ),
                      PriceRow(
                        context.l10n.serviceFee,
                        money(b['fees_usd'] as num),
                        muted: true,
                      ),
                      const Divider(height: 20),
                      PriceRow(
                        context.l10n.total,
                        money(b['total_usd'] as num),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.cancellationPolicy,
                        style: Type.body(15, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b['cancellation_policy'] as String,
                        style: Type.body(
                          13.5,
                          color: Tokens.inkSoft,
                          height: 1.5,
                        ),
                      ),
                      if (b['free_cancel_until'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            context.l10n.freeCancellationUntil(
                              fmtDate(
                                b['free_cancel_until'] as String,
                                pattern: 'EEE d MMM, HH:mm',
                              ),
                            ),
                            style: Type.body(
                              13.5,
                              weight: FontWeight.w800,
                              color: Tokens.primaryText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.statusHistory,
                        style: Type.body(15, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      for (final (i, e) in events.indexed)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(top: 3),
                                    decoration: BoxDecoration(
                                      color: i == events.length - 1
                                          ? Tokens.primary
                                          : Tokens.border,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (i != events.length - 1)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Tokens.border,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        statusLabel(
                                          context.l10n,
                                          e['to_status'] as String,
                                        ),
                                        style: Type.body(
                                          14,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${fmtDate(e['created_at'] as String, pattern: 'd MMM y, HH:mm')}${e['note'] != null ? ' · ${e['note']}' : ''}',
                                        style: Type.body(
                                          12,
                                          color: Tokens.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (payments.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _panel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.payments,
                          style: Type.body(15, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        for (final p in payments)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${money(p['amount_usd'] as num)} · ${p['provider']}${p['simulated'] == true ? context.l10n.simulatedSuffix : ''}',
                                        style: Type.body(
                                          14,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${p['provider_ref']}${p['failure_reason'] != null ? ' · ${p['failure_reason']}' : ''}',
                                        style: Type.body(
                                          12,
                                          color: Tokens.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(p['status'] as String),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Tokens.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Tokens.border),
    ),
    child: child,
  );

  Widget _f(String l, String v, {bool end = false, bool big = false}) => Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(l, style: Type.label(11)),
      const SizedBox(height: 3),
      big
          ? Text(v, style: Type.display(26))
          : Text(
              v,
              style: Type.body(14, weight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: end ? TextAlign.end : TextAlign.start,
            ),
    ],
  );
}

/// Success banner with a check that draws itself in.
class _Confirmed extends StatelessWidget {
  const _Confirmed();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Tokens.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Tokens.success.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (_, v, _) => Transform.scale(
            scale: v.clamp(0.0, 1.3),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Tokens.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.youreBooked, style: Type.display(22)),
              const SizedBox(height: 2),
              Text(
                context.l10n.paymentVerified,
                style: Type.body(12.5, color: Tokens.inkSoft, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
