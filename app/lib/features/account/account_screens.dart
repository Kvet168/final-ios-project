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

export '../auth/auth_screen.dart';

/// Profile tab.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final currency = ref.watch(currencyProvider);
    final meta = ref.watch(metaProvider).value;
    final currencies = ((meta?['currencies'] as List?) ?? const [])
        .cast<Json>();
    final top = MediaQuery.paddingOf(context).top;
    if (auth.isLoading) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, top + 24, 20, 0),
        child: const SkeletonList(count: 2),
      );
    }

    final l = context.l10n;
    final chosenLocale = ref.watch(localeProvider);
    Widget languageSection() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.language, style: Type.display(22)),
          const SizedBox(height: 4),
          Text(
            l.languageNote,
            style: Type.body(12.5, color: Tokens.inkMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WChip(
                l.languageSystem,
                icon: Icons.phone_iphone_rounded,
                selected: chosenLocale == null,
                onTap: () => ref.read(localeProvider.notifier).set(null),
              ),
              WChip(
                'English',
                selected: chosenLocale?.languageCode == 'en',
                onTap: () =>
                    ref.read(localeProvider.notifier).set(const Locale('en')),
              ),
              WChip(
                'ភាសាខ្មែរ',
                selected: chosenLocale?.languageCode == 'km',
                onTap: () =>
                    ref.read(localeProvider.notifier).set(const Locale('km')),
              ),
            ],
          ),
        ],
      ),
    );

    // Required by the MiSans font license: the app notes that MiSans is used.
    Widget credit() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Text(
        l.fontCredit,
        textAlign: TextAlign.center,
        style: Type.body(12, color: Tokens.inkMuted),
      ),
    );

    Widget currencySection() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.displayCurrency, style: Type.display(22)),
          const SizedBox(height: 4),
          Text(
            l.currencyNote,
            style: Type.body(12.5, color: Tokens.inkMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in currencies)
                WChip(
                  c['code'] as String,
                  selected: currency == c['code'],
                  onTap: () => ref
                      .read(currencyProvider.notifier)
                      .set(c['code'] as String),
                ),
            ],
          ),
        ],
      ),
    );

    if (user == null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(0, top + 12, 0, dockClearance(context)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: Tokens.dusk,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l.accountHero,
                    style: Type.display(32, color: Colors.white, height: 1.05),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.accountSignInHint,
                    style: Type.body(
                      14,
                      color: Tokens.onDarkMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.push('/login'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Tokens.cta,
                            foregroundColor: Tokens.onCta,
                          ),
                          child: Text(l.signIn),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          child: Text(l.join),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          languageSection(),
          currencySection(),
          credit(),
        ],
      );
    }

    final role = auth.role;
    final name = user['name'] as String;
    Widget tile(
      IconData i,
      String t,
      String sub,
      String path, {
      Color color = Tokens.primary,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () => context.push(path),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Tokens.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Tokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(i, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t, style: Type.body(15, weight: FontWeight.w800)),
                    Text(sub, style: Type.body(12.5, color: Tokens.inkMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Tokens.inkMuted),
            ],
          ),
        ),
      ),
    );

    return ToneOnScroll(
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, dockClearance(context)),
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, top + 24, 24, 30),
            decoration: const BoxDecoration(
              gradient: Tokens.dusk,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: Tokens.sunrise,
                    border: Border.all(color: Colors.white24, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: Type.display(32, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Type.display(
                          25,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${user['email']}',
                        style: Type.body(12.5, color: Tokens.onDarkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Pill(
                        switch (role) {
                          'admin' => l.roleAdmin,
                          'staff' => l.roleStaff,
                          'partner' => l.rolePartner,
                          'customer' => l.roleCustomer,
                          _ => capitalize(role),
                        },
                        color: Tokens.accent,
                        solid: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tile(
                  Icons.confirmation_number_outlined,
                  l.myBookings,
                  l.myBookingsSub,
                  '/bookings',
                ),
                tile(
                  Icons.favorite_border_rounded,
                  l.wishlist,
                  l.wishlistSub,
                  '/wishlist',
                  color: Tokens.heart,
                ),
                tile(
                  Icons.notifications_none_rounded,
                  l.notifications,
                  l.notificationsSub,
                  '/notifications',
                  color: Tokens.primary,
                ),
                tile(
                  Icons.map_outlined,
                  l.exploreMap,
                  l.exploreMapSub,
                  '/map',
                  color: Tokens.primary,
                ),
                if (auth.isStaff)
                  tile(
                    Icons.admin_panel_settings_outlined,
                    l.administration,
                    l.administrationSub,
                    '/admin',
                    color: Tokens.primary,
                  ),
                if (auth.isPartner)
                  tile(
                    Icons.storefront_outlined,
                    l.partnerPortal,
                    l.partnerPortalSub,
                    '/partner',
                    color: Tokens.primary,
                  ),
              ],
            ),
          ),
          languageSection(),
          currencySection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        title: l.signOut,
                        message: 'Are you sure you want to sign out of your WAYFARER account?',
                        confirmLabel: l.signOut,
                        destructive: true,
                      );
                      if (!ok) return;
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l.signOut),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Tokens.danger),
                  onPressed: () => _delete(context, ref),
                  child: Text(l.deleteMyAccount),
                ),
              ],
            ),
          ),
          credit(),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final pw = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.deleteAccountQ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.deleteAccountBody,
              style: Type.body(14, color: Tokens.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.l10n.confirmPassword,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.l10n.keepAccount),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Tokens.danger,
              minimumSize: const Size(0, 46),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(apiProvider)
          .postEmpty('/users/me/delete', body: {'password': pw.text});
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
              title: Text(context.l10n.wishlist, style: Type.display(26)),
            ),
          ),
          SliverToBoxAdapter(
            child: res.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: SkeletonList(count: 3, itemHeight: 100),
              ),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(wishlistProvider),
              ),
              data: (r) {
                final items = (r['items'] as List).cast<Json>();
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: context.l10n.nothingSavedYet,
                    message: context.l10n.nothingSavedHint,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    children: [
                      for (final (n, i) in items.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Reveal(
                            delay: Duration(milliseconds: 50 * n),
                            child: Pressable(
                              onTap: () {
                                final slug = i['slug'];
                                if (i['kind'] == 'destination') {
                                  context.push('/destinations/$slug');
                                }
                                if (i['kind'] == 'accommodation') {
                                  context.push('/stays/$slug');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Tokens.surface,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Tokens.border),
                                ),
                                child: Row(
                                  children: [
                                    WImage(
                                      i['image'] as String?,
                                      width: 80,
                                      height: 80,
                                      radius: 16,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (i['name'] ??
                                                    context.l10n.savedItem)
                                                as String,
                                            style: Type.display(
                                              19,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Pill(
                                            i['kind'] == 'accommodation'
                                                ? context.l10n.stay
                                                : categoryLabel(
                                                    context.l10n,
                                                    i['kind'] as String,
                                                  ),
                                            color: Tokens.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: context.l10n.removeFromWishlist,
                                      icon: const Icon(
                                        Icons.favorite_rounded,
                                        color: Tokens.heart,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(apiProvider)
                                            .delete(
                                              '/wishlist/${i['kind']}/${i['ref_id']}',
                                            );
                                        ref.invalidate(wishlistProvider);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(notificationsProvider);
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
              title: Text(context.l10n.notifications, style: Type.display(26)),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await ref
                      .read(apiProvider)
                      .postEmpty('/notifications/read-all');
                  ref.invalidate(notificationsProvider);
                },
                child: Text(context.l10n.markAllRead),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: res.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: SkeletonList(count: 4, itemHeight: 84),
              ),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              data: (r) {
                final items = (r['items'] as List).cast<Json>();
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: context.l10n.allCaughtUp,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          context.l10n.inAppOnlyNote,
                          style: Type.body(12, color: Tokens.inkMuted),
                        ),
                      ),
                      for (final n in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Pressable(
                            onTap: () async {
                              await ref
                                  .read(apiProvider)
                                  .patchEmpty('/notifications/${n['id']}/read');
                              ref.invalidate(notificationsProvider);
                              final bid = (n['data'] as Map?)?['bookingId'];
                              if (bid != null && context.mounted) {
                                context.push('/bookings/$bid');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n['read_at'] == null
                                    ? Tokens.tint.withValues(alpha: .55)
                                    : Tokens.surface,
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
                                      color: Tokens.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      n['type'] == 'payment'
                                          ? Icons.payments_outlined
                                          : n['type'] == 'itinerary'
                                          ? Icons.map_outlined
                                          : Icons.confirmation_number_outlined,
                                      color: Tokens.primary,
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n['title'] as String,
                                          style: Type.body(
                                            14.5,
                                            weight: n['read_at'] == null
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${n['body']}',
                                          style: Type.body(
                                            13,
                                            color: Tokens.inkSoft,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          fmtDate(
                                            n['created_at'] as String,
                                            pattern: 'd MMM y, HH:mm',
                                          ),
                                          style: Type.body(
                                            11.5,
                                            color: Tokens.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (n['read_at'] == null)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: const BoxDecoration(
                                        color: Tokens.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
    );
  }
}

IconData categoryIconFor(String c) => categoryIcon(c);
