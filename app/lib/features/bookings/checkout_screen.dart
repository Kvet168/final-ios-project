import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';

/// Two-step checkout: (1) guest details + price review creates a held booking, (2) simulated payment.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.roomTypeId, required this.params});
  final String roomTypeId;
  final Map<String, String> params;
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  Json? quote;
  Json? booking;
  Json? payment;
  Object? error;
  bool busy = false, loading = true, prefilled = false;
  Timer? _tick;
  Duration? _left;
  late final String _idem = 'wf-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  String? get existingBooking => widget.params['bookingId'];
  String get ci => widget.params['checkIn'] ?? '';
  String get co => widget.params['checkOut'] ?? '';
  int get rooms => int.tryParse(widget.params['rooms'] ?? '') ?? (booking?['rooms'] as int? ?? 1);
  int get adults => int.tryParse(widget.params['adults'] ?? '') ?? (booking?['adults'] as int? ?? 2);
  int get children => int.tryParse(widget.params['children'] ?? '') ?? (booking?['children'] as int? ?? 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final c in [_name, _email, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      if (existingBooking != null) {
        // Resume payment for a booking that is already held: never create a second booking.
        final b = await ref.read(apiProvider).getJson('/bookings/$existingBooking');
        if (b['status'] != 'PENDING_CONFIRMATION') {
          error = ApiException('This booking is ${(b['status'] as String).replaceAll('_', ' ').toLowerCase()} and can no longer be paid.', code: 'NOT_PAYABLE');
        } else {
          booking = b;
          quote = {
            'accommodationName': b['accommodation_name'], 'roomName': b['room_name'], 'available': true,
            'nightly': (b['nights_detail'] as List).map((n) => {'night': n['night'], 'rate_usd': n['rate_usd']}).toList(),
            'subtotal_usd': b['subtotal_usd'], 'taxes_usd': b['taxes_usd'], 'fees_usd': b['fees_usd'], 'total_usd': b['total_usd'],
            'cancellationPolicy': b['cancellation_policy'],
          };
          _startCountdown(b['hold_expires_at'] as String?);
        }
        if (mounted) setState(() => loading = false);
        return;
      }
      quote = await ref.read(apiProvider).postJson('/bookings/quote', body: {'roomTypeId': widget.roomTypeId, 'checkIn': ci, 'checkOut': co, 'rooms': rooms});
    } catch (e) {
      error = e;
    }
    if (mounted) setState(() => loading = false);
  }

  void _startCountdown(String? holdIso) {
    _tick?.cancel();
    if (holdIso == null) return;
    final end = DateTime.tryParse(holdIso)?.toLocal();
    if (end == null) return;
    void update() => setState(() => _left = end.difference(DateTime.now()));
    update();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  Future<void> _createBooking() async {
    if (!_form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      booking = await ref.read(apiProvider).postJson('/bookings', body: {
        'roomTypeId': widget.roomTypeId, 'checkIn': ci, 'checkOut': co, 'rooms': rooms, 'adults': adults, 'children': children,
        'guestName': _name.text.trim(), 'guestEmail': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'guestPhone': _phone.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'specialRequests': _notes.text.trim(),
      });
      _startCountdown(booking!['hold_expires_at'] as String?);
    } catch (e) {
      if (mounted) showError(context, e);
      if (e is ApiException && e.code == 'NO_AVAILABILITY') setState(() => error = e);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _pay(String outcome) async {
    setState(() { busy = true; });
    try {
      final api = ref.read(apiProvider);
      payment ??= await api.postJson('/payments/intent', body: {'bookingId': booking!['id'], 'idempotencyKey': _idem});
      final r = await api.postJson('/payments/${payment!['id']}/simulate', body: {'outcome': outcome});
      final status = (r['payment'] as Json)['status'];
      if (status == 'SUCCESS') {
        ref.invalidate(bookingsProvider);
        ref.invalidate(notificationsProvider);
        if (mounted) context.go('/bookings/${booking!['id']}?paid=1');
        return;
      }
      payment = null; // failed/cancelled: allow a retry with a fresh intent
      if (mounted) showError(context, ApiException('Payment ${status.toString().toLowerCase()} (simulated). Your booking is not confirmed — you can try again before the hold expires.'));
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => busy = false);
  }

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(18)}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Tokens.border), boxShadow: Tokens.softShadow(0.05)),
        child: child,
      );

  Widget _step(int n, String label, bool on, bool done) => Expanded(
        child: Column(children: [
          Row(children: [
            Expanded(child: Container(height: 3, color: n == 1 ? Colors.transparent : (on || done ? Tokens.primary : Tokens.border))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: on || done ? Tokens.primary : Tokens.surface, shape: BoxShape.circle, border: Border.all(color: on || done ? Tokens.primary : Tokens.border, width: 1.6)),
              child: Center(child: done ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : Text('$n', style: Type.body(13, weight: FontWeight.w800, color: on ? Colors.white : Tokens.inkMuted))),
            ),
            Expanded(child: Container(height: 3, color: n == 3 ? Colors.transparent : (done ? Tokens.primary : Tokens.border))),
          ]),
          const SizedBox(height: 6),
          Text(label, style: Type.body(11.5, weight: on ? FontWeight.w800 : FontWeight.w600, color: on || done ? Tokens.primaryText : Tokens.inkMuted)),
        ]),
      );

  Widget _when(String label, String value, {bool end = false}) => Column(
        crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [Text(label, style: Type.label(10)), const SizedBox(height: 4), Text(value, style: Type.body(15, weight: FontWeight.w800))],
      );

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyProvider);
    final user = ref.watch(authProvider).user;
    if (user != null && !prefilled) {
      prefilled = true;
      _name.text = (user['name'] ?? '') as String;
      _email.text = (user['email'] ?? '') as String;
      _phone.text = (user['phone'] ?? '') as String;
    }
    final nights = nightsBetween(booking?['check_in'] as String? ?? ci, booking?['check_out'] as String? ?? co);
    final ciS = booking?['check_in'] as String? ?? ci, coS = booking?['check_out'] as String? ?? co;

    Widget summary() {
      if (loading) return const SkeletonList(count: 1, itemHeight: 260);
      if (quote == null) return ErrorState(error: error ?? 'Unknown error', onRetry: _load);
      final q = quote!;
      return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('YOUR STAY', style: Type.label(10.5, color: Tokens.warning)),
        const SizedBox(height: 8),
        Text(q['accommodationName'] as String, style: Type.display(24, height: 1.1)),
        const SizedBox(height: 2),
        Text(q['roomName'] as String, style: Type.body(14, color: Tokens.inkMuted)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _when('CHECK-IN', fmtDate(ciS, pattern: 'EEE d MMM'))),
          Container(width: 54, alignment: Alignment.center, child: Column(children: [Text('$nights', style: Type.display(20, height: 1)), Text(nights == 1 ? 'night' : 'nights', style: Type.body(10.5, color: Tokens.inkMuted))])),
          Expanded(child: _when('CHECK-OUT', fmtDate(coS, pattern: 'EEE d MMM'), end: true)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.people_outline, size: 18, color: Tokens.primary),
          const SizedBox(width: 8),
          Text('$adults adult${adults > 1 ? 's' : ''}${children > 0 ? ', $children child${children > 1 ? 'ren' : ''}' : ''} · $rooms room${rooms > 1 ? 's' : ''}', style: Type.body(13.5, weight: FontWeight.w600)),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: DashedLine()),
        for (final n in (q['nightly'] as List).cast<Json>()) PriceRow(fmtDate(n['night'] as String, pattern: 'EEE d MMM'), money((n['rate_usd'] as num) * rooms), muted: true),
        const SizedBox(height: 6),
        PriceRow('Room subtotal', money(q['subtotal_usd'] as num)),
        PriceRow('Taxes', money(q['taxes_usd'] as num), muted: true),
        PriceRow('Service fee', money(q['fees_usd'] as num), muted: true),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
        PriceRow('Total', money(q['total_usd'] as num), bold: true),
        if (q['available'] != true) Padding(padding: const EdgeInsets.only(top: 12), child: Text(q['reason'] as String? ?? 'No longer available', style: Type.body(13.5, color: Tokens.danger))),
        const SizedBox(height: 12),
        Text(q['cancellationPolicy'] as String, style: Type.body(12.5, color: Tokens.inkMuted, height: 1.5)),
      ]));
    }

    Widget details() => Form(
          key: _form,
          child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Guest details', style: Type.display(24)),
            const SizedBox(height: 16),
            TextFormField(controller: _name, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name], decoration: const InputDecoration(labelText: 'Full name (as on ID)', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the guest name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email'),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, maxLines: 3, maxLength: 500, decoration: const InputDecoration(labelText: 'Special requests (optional)')),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy || quote == null || quote!['available'] != true ? null : _createBooking,
                child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Continue to payment'),
              ),
            ),
            const SizedBox(height: 12),
            Text('Your room is held for a short time while you pay. A booking is only confirmed after payment is verified by the server.', style: Type.body(12, color: Tokens.inkMuted, height: 1.5)),
          ])),
        );

    Widget payStep() {
      final left = _left;
      final expired = left != null && left.isNegative;
      final mm = left == null ? '--' : left.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = left == null ? '--' : left.inSeconds.remainder(60).toString().padLeft(2, '0');
      return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Payment', style: Type.display(24)),
        const SizedBox(height: 12),
        Pill(expired ? 'Hold expired' : 'Room held for $mm:$ss', color: expired ? Tokens.danger : Tokens.warning, icon: Icons.timer_outlined),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Tokens.promo, borderRadius: BorderRadius.circular(16)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.science_outlined, size: 20, color: Tokens.warning),
            const SizedBox(width: 10),
            Expanded(child: Text('Simulated payment. This demo uses a mock payment provider: no card is charged and no real money moves. Choose an outcome to test how the booking reacts.', style: Type.body(13, height: 1.5))),
          ]),
        ),
        const SizedBox(height: 18),
        Text('Reference ${booking!['reference']}', style: Type.body(13.5, weight: FontWeight.w700, color: Tokens.inkMuted)),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Amount due  ', style: Type.body(14, color: Tokens.inkMuted)), Text(money(booking!['total_usd'] as num), style: Type.display(30, height: 1))]),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy || expired ? null : () => _pay('success'), icon: const Icon(Icons.lock_outline_rounded), label: const Text('Pay now (simulate success)'))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: busy || expired ? null : () => _pay('fail'), child: const Text('Simulate a declined card'))),
        const SizedBox(height: 4),
        Center(child: TextButton(onPressed: busy ? null : () => context.go('/bookings/${booking!['id']}'), child: const Text('Pay later from My bookings'))),
      ]));
    }

    final step = booking == null ? 2 : 3;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
          Row(children: [
            IconButton(tooltip: 'Back', onPressed: () => context.canPop() ? context.pop() : context.go('/stays'), icon: const Icon(Icons.arrow_back_rounded)),
            Text('Checkout', style: Type.display(26)),
          ]),
          const SizedBox(height: 8),
          Row(children: [_step(1, 'Room', false, true), _step(2, 'Details', step == 2, step > 2), _step(3, 'Payment', step == 3, false)]),
          const SizedBox(height: 20),
          summary(),
          const SizedBox(height: 18),
          booking == null ? details() : payStep(),
        ]),
      ),
    );
  }
}
