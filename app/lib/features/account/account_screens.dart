import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/settings_ui.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';

export '../auth/auth_screen.dart';

/// Profile tab, laid out like a settings screen: profile card, then small headings over rounded groups.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    String? note,
    required List<(T, String, String?)> options,
    required T selected,
    required void Function(T) onPick,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(title, style: Type.display(20)),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(
                note,
                style: Type.body(12.5, color: Tokens.inkMuted, height: 1.4),
              ),
            ],
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (value, label, sub) in options)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 10,
                      title: Text(
                        label,
                        style: Type.body(15.5, weight: FontWeight.w600),
                      ),
                      subtitle: sub == null
                          ? null
                          : Text(
                              sub,
                              style: Type.body(12.5, color: Tokens.inkMuted),
                            ),
                      trailing: value == selected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Tokens.primary,
                            )
                          : const Icon(
                              Icons.circle_outlined,
                              color: Tokens.border,
                            ),
                      onTap: () {
                        onPick(value);
                        Navigator.pop(c);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

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
    final languageValue = chosenLocale == null
        ? l.languageSystem
        : chosenLocale.languageCode == 'km'
        ? 'ភាសាខ្មែរ'
        : 'English';

    final general = SettingsGroup(
      children: [
        SettingsRow(
          icon: Icons.translate_rounded,
          title: l.language,
          value: languageValue,
          onTap: () => _pick<String>(
            context,
            title: l.language,
            note: l.languageNote,
            selected: chosenLocale?.languageCode ?? 'system',
            options: [
              ('system', l.languageSystem, null),
              ('en', 'English', null),
              ('km', 'ភាសាខ្មែរ', null),
            ],
            onPick: (v) => ref
                .read(localeProvider.notifier)
                .set(v == 'system' ? null : Locale(v)),
          ),
        ),
        SettingsRow(
          icon: Icons.payments_outlined,
          title: l.displayCurrency,
          value: currency,
          onTap: () => _pick<String>(
            context,
            title: l.displayCurrency,
            note: l.currencyNote,
            selected: currency,
            options: [
              for (final c in currencies)
                (
                  c['code'] as String,
                  '${c['code']}  ${c['symbol'] ?? ''}'.trim(),
                  c['name'] as String?,
                ),
            ],
            onPick: (v) => ref.read(currencyProvider.notifier).set(v),
          ),
        ),
      ],
    );

    final name = user == null ? '' : '${user['name']}';
    final role = auth.role;
    final profile = user == null
        ? Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Tokens.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.accountSignInHint,
                  style: Type.body(14, color: Tokens.inkSoft, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push('/login'),
                        child: Text(l.signIn),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/register'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: Text(l.join),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        : Material(
            color: Tokens.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/account/edit'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ProfileAvatar(
                      name: name,
                      url: '${user['avatarUrl'] ?? ''}',
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Type.display(18, height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user['email']}',
                            style: Type.body(13, color: Tokens.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (role != 'customer') ...[
                            const SizedBox(height: 8),
                            Pill(switch (role) {
                              'admin' => l.roleAdmin,
                              'staff' => l.roleStaff,
                              'partner' => l.rolePartner,
                              _ => capitalize(role),
                            }, color: Tokens.accent),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Tokens.inkMuted.withValues(alpha: .6),
                    ),
                  ],
                ),
              ),
            ),
          );

    return ColoredBox(
      color: Tokens.pageBg,
      child: StatusTone.light(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            top + 16,
            20,
            dockClearance(context),
          ),
          children: [
            Text(l.tabMe, style: Type.display(28)),
            const SizedBox(height: 16),
            profile,
            if (user != null) ...[
              SectionHeading(l.accountSectionActivity),
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.confirmation_number_outlined,
                    title: l.myBookings,
                    onTap: () => context.push('/bookings'),
                  ),
                  SettingsRow(
                    icon: Icons.favorite_border_rounded,
                    title: l.wishlist,
                    onTap: () => context.push('/wishlist'),
                  ),
                  SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: l.notifications,
                    onTap: () => context.push('/notifications'),
                  ),
                  SettingsRow(
                    icon: Icons.map_outlined,
                    title: l.exploreMap,
                    onTap: () => context.push('/map'),
                  ),
                ],
              ),
              if (auth.isStaff || auth.isPartner) ...[
                SectionHeading(l.accountSectionManage),
                SettingsGroup(
                  children: [
                    if (auth.isStaff)
                      SettingsRow(
                        icon: Icons.admin_panel_settings_outlined,
                        title: l.administration,
                        onTap: () => context.push('/admin'),
                      ),
                    if (auth.isPartner)
                      SettingsRow(
                        icon: Icons.storefront_outlined,
                        title: l.partnerPortal,
                        onTap: () => context.push('/partner'),
                      ),
                  ],
                ),
              ],
            ],
            SectionHeading(l.accountSectionGeneral),
            general,
            if (user != null) ...[
              SectionHeading(l.accountSectionAccount),
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.person_outline_rounded,
                    title: l.editProfile,
                    onTap: () => context.push('/account/edit'),
                  ),
                  SettingsRow(
                    icon: Icons.logout_rounded,
                    title: l.signOut,
                    chevron: false,
                    onTap: () async {
                      final ok = await confirm(
                        context,
                        title: l.signOut,
                        message: l.signOutConfirm,
                        confirmLabel: l.signOut,
                        destructive: true,
                      );
                      if (!ok) return;
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/');
                    },
                  ),
                  SettingsRow(
                    icon: Icons.delete_outline_rounded,
                    title: l.deleteAccountTitle,
                    danger: true,
                    onTap: () => context.push('/account/delete'),
                  ),
                ],
              ),
            ],
            // Required by the MiSans font license: the app notes that MiSans is used.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
              child: Text(
                l.fontCredit,
                style: Type.body(12, color: Tokens.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(wishlistProvider);
    final l = context.l10n;
    return SubPage(
      title: l.wishlist,
      children: [
        res.when(
          loading: () => const SkeletonList(count: 3, itemHeight: 100),
          error: (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(wishlistProvider),
          ),
          data: (r) {
            final items = (r['items'] as List).cast<Json>();
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: EmptyPanel(
                  icon: Icons.favorite_border_rounded,
                  title: l.nothingSavedYet,
                  message: l.nothingSavedHint,
                  actionLabel: l.browseDestinations,
                  onAction: () => context.go('/destinations'),
                ),
              );
            }
            return Column(
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              WImage(
                                i['image'] as String?,
                                width: 80,
                                height: 80,
                                radius: 14,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (i['name'] ?? l.savedItem) as String,
                                      style: Type.display(17, height: 1.2),
                                    ),
                                    const SizedBox(height: 6),
                                    Pill(
                                      i['kind'] == 'accommodation'
                                          ? l.stay
                                          : categoryLabel(
                                              l,
                                              i['kind'] as String,
                                            ),
                                      color: Tokens.primary,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: l.removeFromWishlist,
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
            );
          },
        ),
      ],
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(notificationsProvider);
    final l = context.l10n;
    return SubPage(
      title: l.notifications,
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(apiProvider).postEmpty('/notifications/read-all');
            ref.invalidate(notificationsProvider);
          },
          child: Text(l.markAllRead),
        ),
      ],
      children: [
        res.when(
          loading: () => const SkeletonList(count: 4, itemHeight: 84),
          error: (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (r) {
            final items = (r['items'] as List).cast<Json>();
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: EmptyPanel(
                  icon: Icons.notifications_none_rounded,
                  title: l.allCaughtUp,
                  message: l.notificationsEmptyHint,
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.zero,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}

IconData categoryIconFor(String c) => categoryIcon(c);
