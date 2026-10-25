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

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.register, this.next});
  final bool register;
  final String? next;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool busy = false, hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      final auth = ref.read(authProvider.notifier);
      if (widget.register) {
        await auth.register(_name.text.trim(), _email.text.trim(), _pw.text);
      } else {
        await auth.login(_email.text.trim(), _pw.text);
      }
      ref.invalidate(wishlistProvider);
      if (mounted) context.go(widget.next ?? '/account');
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.register;
    final nextQ = widget.next == null ? '' : '?next=${Uri.encodeComponent(widget.next!)}';
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return StatusTone.light(child: Scaffold(
      backgroundColor: Tokens.pageBg,
      body: Stack(fit: StackFit.expand, children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 360,
          child: Stack(fit: StackFit.expand, children: [
            Container(decoration: const BoxDecoration(gradient: Tokens.dusk)),
            WImage('https://x/img/22c5bab2e68b0b85.jpg', full: true, width: double.infinity, height: double.infinity),
            const Scrim(top: true, strength: 0.9),
            Positioned(
              left: 26,
              bottom: 70,
              right: 26,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.explore_rounded, color: Tokens.onDarkAccent, size: 22), const SizedBox(width: 8), Text('WAYFARER', style: Type.display(15, color: Colors.white, spacing: 3))]),
                const SizedBox(height: 14),
                Text(reg ? 'Begin your\nnext journey.' : 'Welcome\nback, traveller.', style: Type.display(38, color: Colors.white, height: 1.02)),
              ]),
            ),
          ]),
        ),
        Positioned(top: MediaQuery.paddingOf(context).top + 8, left: 12, child: GlassIconButton(icon: Icons.close_rounded, tooltip: 'Close', onTap: () => context.canPop() ? context.pop() : context.go('/'))),
        Positioned.fill(
          top: 290 - (kb > 0 ? 160 : 0),
          child: Container(
            decoration: const BoxDecoration(color: Tokens.pageBg, borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + kb),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(reg ? 'Create your account' : 'Sign in', style: Type.display(26)),
                    const SizedBox(height: 4),
                    Text(reg ? 'Save trips, manage bookings and keep a wishlist.' : 'Manage bookings and saved trips.', style: Type.body(14, color: Tokens.inkMuted)),
                    const SizedBox(height: 22),
                    if (reg) ...[
                      TextFormField(controller: _name, autofillHints: const [AutofillHints.name], textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(controller: _email, autofillHints: const [AutofillHints.email], keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (v) => _emailRe.hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pw,
                      obscureText: hide,
                      autofillHints: [reg ? AutofillHints.newPassword : AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: reg ? 'At least 10 characters, with letters and a number' : null,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(tooltip: hide ? 'Show password' : 'Hide password', icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => hide = !hide)),
                      ),
                      validator: (v) {
                        final s = v ?? '';
                        if (s.isEmpty) return 'Enter your password';
                        if (reg && (s.length < 10 || !RegExp(r'\d').hasMatch(s) || !RegExp(r'[a-zA-Z]').hasMatch(s))) return 'Use 10+ characters with letters and a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: busy ? null : _submit, child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(reg ? 'Create account' : 'Sign in')),
                    if (!reg) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () {
                          _email.text = 'maya@demo.wayfarer.test';
                          _pw.text = 'Wayfarer#Demo2026';
                          _submit();
                        },
                        icon: const Icon(Icons.bolt_rounded, color: Tokens.accent),
                        label: const Text('Try the demo account'),
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextButton(onPressed: () => context.go(reg ? '/login$nextQ' : '/register$nextQ'), child: Text(reg ? 'Already have an account? Sign in' : 'New here? Create an account')),
                    if (!reg) TextButton(onPressed: () => _forgot(context), child: const Text('Forgot password?')),
                    if (!reg) Padding(padding: const EdgeInsets.only(top: 6), child: Text('The demo account is a sample customer (Maya). Staff, partner and admin accounts are issued by the project owner.', textAlign: TextAlign.center, style: Type.body(11.5, color: Tokens.inkMuted, height: 1.45))),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    ));
  }

  Future<void> _forgot(BuildContext context) async {
    final email = TextEditingController(text: _email.text);
    String? message;
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Reset password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () async {
                try {
                  final r = await ref.read(apiProvider).postJson('/auth/forgot-password', body: {'email': email.text.trim()});
                  set(() => message = '${r['message']}${r['demoResetToken'] != null ? '\n\nDemo mode (no email provider): use token ${r['demoResetToken']} via the API /auth/reset-password.' : ''}');
                } catch (e) {
                  set(() => message = e.toString());
                }
              },
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile tab.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final currency = ref.watch(currencyProvider);
    final meta = ref.watch(metaProvider).value;
    final currencies = ((meta?['currencies'] as List?) ?? const []).cast<Json>();
    final top = MediaQuery.paddingOf(context).top;
    if (auth.isLoading) return Padding(padding: EdgeInsets.fromLTRB(20, top + 24, 20, 0), child: const SkeletonList(count: 2));

    Widget currencySection() => Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Display currency', style: Type.display(22)),
            const SizedBox(height: 4),
            Text('Prices are stored in USD and converted with documented sample rates, not live market rates.', style: Type.body(12.5, color: Tokens.inkMuted, height: 1.4)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final c in currencies) WChip(c['code'] as String, selected: currency == c['code'], onTap: () => ref.read(currencyProvider.notifier).set(c['code'] as String))]),
          ]),
        );

    if (user == null) {
      return ListView(padding: EdgeInsets.fromLTRB(0, top + 12, 0, dockClearance(context)), children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(gradient: Tokens.dusk, borderRadius: BorderRadius.circular(30)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.explore_rounded, color: Tokens.onDarkAccent, size: 34),
              const SizedBox(height: 18),
              Text('Your travel\nlife, in one place.', style: Type.display(32, color: Colors.white, height: 1.05)),
              const SizedBox(height: 10),
              Text('Sign in to see bookings, saved trips and your wishlist.', style: Type.body(14, color: Tokens.onDarkMuted, height: 1.5)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: FilledButton(onPressed: () => context.push('/login'), style: FilledButton.styleFrom(backgroundColor: Tokens.cta, foregroundColor: Tokens.onCta), child: const Text('Sign in'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: () => context.push('/register'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)), child: const Text('Join'))),
              ]),
            ]),
          ),
        ),
        currencySection(),
      ]);
    }

    final role = auth.role;
    final name = user['name'] as String;
    Widget tile(IconData i, String t, String sub, String path, {Color color = Tokens.primary}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Pressable(
            onTap: () => context.push(path),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: Tokens.border)),
              child: Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: Icon(i, color: color)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: Type.body(15, weight: FontWeight.w800)), Text(sub, style: Type.body(12.5, color: Tokens.inkMuted))])),
                const Icon(Icons.chevron_right_rounded, color: Tokens.inkMuted),
              ]),
            ),
          ),
        );

    return ToneOnScroll(child: ListView(padding: EdgeInsets.fromLTRB(0, 0, 0, dockClearance(context)), children: [
      Container(
        padding: EdgeInsets.fromLTRB(24, top + 24, 24, 30),
        decoration: const BoxDecoration(gradient: Tokens.dusk, borderRadius: BorderRadius.vertical(bottom: Radius.circular(34))),
        child: Row(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: Tokens.sunrise, border: Border.all(color: Colors.white24, width: 3)),
            child: Center(child: Text(name.substring(0, 1).toUpperCase(), style: Type.display(32, color: Colors.white))),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: Type.display(25, color: Colors.white, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('${user['email']}', style: Type.body(12.5, color: Tokens.onDarkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Pill(capitalize(role), color: Tokens.accent, solid: true),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          tile(Icons.confirmation_number_outlined, 'My bookings', 'Tickets, cancellation and receipts', '/bookings'),
          tile(Icons.favorite_border_rounded, 'Wishlist', 'Saved destinations and stays', '/wishlist', color: Tokens.heart),
          tile(Icons.notifications_none_rounded, 'Notifications', 'Booking and payment updates', '/notifications', color: Tokens.primary),
          tile(Icons.map_outlined, 'Explore map', 'Destinations and stays near you', '/map', color: Tokens.primary),
          if (auth.isStaff) tile(Icons.admin_panel_settings_outlined, 'Administration', 'Overview, bookings, payments, reviews, audit log', '/admin', color: Tokens.charcoal),
          if (auth.isPartner) tile(Icons.storefront_outlined, 'Partner portal', 'Your properties, bookings and availability', '/partner', color: Tokens.charcoal),
        ]),
      ),
      currencySection(),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
          TextButton(style: TextButton.styleFrom(foregroundColor: Tokens.danger), onPressed: () => _delete(context, ref), child: const Text('Delete my account')),
        ]),
      ),
    ]));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final pw = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Your profile is anonymised and you will be signed out. Active bookings must be cancelled first. This cannot be undone.', style: Type.body(14, color: Tokens.inkSoft, height: 1.5)),
          const SizedBox(height: 12),
          TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep account')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Tokens.danger, minimumSize: const Size(0, 46)), onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiProvider).postEmpty('/users/me/delete', body: {'password': pw.text});
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(wishlistProvider);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(pinned: true, expandedHeight: 120, backgroundColor: Tokens.pageBg, surfaceTintColor: Colors.transparent, flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14), title: Text('Wishlist', style: Type.display(26)))),
        SliverToBoxAdapter(
          child: res.when(
            loading: () => const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 3, itemHeight: 100)),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(wishlistProvider)),
            data: (r) {
              final items = (r['items'] as List).cast<Json>();
              if (items.isEmpty) return const EmptyState(icon: Icons.favorite_border_rounded, title: 'Nothing saved yet', message: 'Tap the heart on a destination or stay to keep it here.');
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                child: Column(children: [
                  for (final (n, i) in items.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Reveal(
                        delay: Duration(milliseconds: 50 * n),
                        child: Pressable(
                          onTap: () {
                            final slug = i['slug'];
                            if (i['kind'] == 'destination') context.push('/destinations/$slug');
                            if (i['kind'] == 'accommodation') context.push('/stays/$slug');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: Tokens.border)),
                            child: Row(children: [
                              WImage(i['image'] as String?, width: 80, height: 80, radius: 16),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((i['name'] ?? 'Saved item') as String, style: Type.display(19, height: 1.1)), const SizedBox(height: 4), Pill(i['kind'] == 'accommodation' ? 'Stay' : capitalize(i['kind'] as String), color: Tokens.primary)])),
                              IconButton(
                                tooltip: 'Remove from wishlist',
                                icon: const Icon(Icons.favorite_rounded, color: Tokens.heart),
                                onPressed: () async {
                                  await ref.read(apiProvider).delete('/wishlist/${i['kind']}/${i['ref_id']}');
                                  ref.invalidate(wishlistProvider);
                                },
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(notificationsProvider);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          backgroundColor: Tokens.pageBg,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14), title: Text('Notifications', style: Type.display(26))),
          actions: [
            TextButton(
              onPressed: () async {
                await ref.read(apiProvider).postEmpty('/notifications/read-all');
                ref.invalidate(notificationsProvider);
              },
              child: const Text('Mark all read'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: res.when(
            loading: () => const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 4, itemHeight: 84)),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(notificationsProvider)),
            data: (r) {
              final items = (r['items'] as List).cast<Json>();
              if (items.isEmpty) return const EmptyState(icon: Icons.notifications_none_rounded, title: "You're all caught up");
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                child: Column(children: [
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('In-app notifications only. Push delivery needs Firebase credentials and is not configured.', style: Type.body(11.5, color: Tokens.inkMuted))),
                  for (final n in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Pressable(
                        onTap: () async {
                          await ref.read(apiProvider).patchEmpty('/notifications/${n['id']}/read');
                          ref.invalidate(notificationsProvider);
                          final bid = (n['data'] as Map?)?['bookingId'];
                          if (bid != null && context.mounted) context.push('/bookings/$bid');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: n['read_at'] == null ? Tokens.tint.withValues(alpha: .55) : Tokens.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Tokens.border)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 42, height: 42, decoration: BoxDecoration(color: Tokens.surface, shape: BoxShape.circle), child: Icon(n['type'] == 'payment' ? Icons.payments_outlined : n['type'] == 'itinerary' ? Icons.map_outlined : Icons.confirmation_number_outlined, color: Tokens.primary, size: 21)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n['title'] as String, style: Type.body(14.5, weight: n['read_at'] == null ? FontWeight.w800 : FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('${n['body']}', style: Type.body(13, color: Tokens.inkSoft, height: 1.4)),
                                const SizedBox(height: 4),
                                Text(fmtDate(n['created_at'] as String, pattern: 'd MMM y, HH:mm'), style: Type.body(11.5, color: Tokens.inkMuted)),
                              ]),
                            ),
                            if (n['read_at'] == null) Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: Tokens.primary, shape: BoxShape.circle)),
                          ]),
                        ),
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

IconData categoryIconFor(String c) => categoryIcon(c);
