import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';

/// Shared brand-red header banner for the in-app Admin Console and Partner Portal, matching [AccountScreen].
class _PortalHeader extends ConsumerWidget {
  const _PortalHeader({
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    required this.icon,
  });
  final String title, subtitle, roleLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final auth = ref.watch(authProvider);
    final chosenLocale = ref.watch(localeProvider);
    final isKm =
        (chosenLocale?.languageCode ??
            Localizations.localeOf(context).languageCode) ==
        'km';
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 26),
      decoration: const BoxDecoration(
        gradient: Tokens.dusk,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: context.l10n.close,
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/account'),
              ),
              const SizedBox(width: 12),
              Image.asset('assets/logo.png', height: 24),
 const Spacer(),
              GestureDetector(
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .set(Locale(isKm ? 'en' : 'km')),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isKm ? 'ខ្មែរ · EN' : 'EN · ខ្មែរ',
                        style: Type.body(
                          12,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pill(roleLabel, color: Tokens.accent, icon: icon, solid: true),
              if (auth.signedIn) ...[
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: context.l10n.signOut,
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      title: '${context.l10n.signOut}?',
                      message: 'Are you sure you want to sign out of your Travel account?',
                      confirmLabel: context.l10n.signOut,
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/');
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Type.display(28, color: Colors.white, height: 1.08),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Type.body(13, color: Tokens.onDarkMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Celebratory success pop-up dialog with checkmark badge and summary receipt rows.
Future<void> _showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  List<(String, String)> details = const [],
}) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF48EC86), Color(0xFF1F8F5F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF48EC86).withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Type.display(21)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Type.body(13.5, color: Tokens.inkMuted, height: 1.45),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Tokens.pageBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Tokens.border),
              ),
              child: Column(
                children: [
                  for (final (i, kv) in details.indexed) ...[
                    if (i > 0) const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kv.$1,
                          style: Type.body(12.5, color: Tokens.inkMuted),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            kv.$2,
                            textAlign: TextAlign.end,
                            style: Type.body(13, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    actions: [
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(c),
          child: Text(context.l10n.done),
        ),
      ),
    ],
  ),
);

/// Server-authorised admin console. The API enforces roles; this UI merely reflects 401/403 responses.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int tab = 0;
  static List<(String, IconData)> tabsFor(AppLocalizations l) => [
    (l.adminOverview, Icons.dashboard_outlined),
    (l.adminBookings, Icons.luggage_outlined),
    (l.adminPayments, Icons.payments_outlined),
    (l.adminUsers, Icons.people_outline),
    (l.adminReviews, Icons.rate_review_outlined),
    (l.adminContent, Icons.edit_location_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final l = context.l10n;
    if (!auth.isStaff) {
      return Scaffold(
        backgroundColor: Tokens.pageBg,
        body: Column(
          children: [
            _PortalHeader(
              title: l.administration,
              subtitle: l.administrationSub,
              roleLabel: l.roleCustomer,
              icon: Icons.lock_outline_rounded,
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.lock_outline_rounded,
                title: l.adminAccessRequired,
                message: l.adminAccessHint,
              ),
            ),
          ],
        ),
      );
    }
    final isAdmin = auth.role == 'admin';
    final tabs = tabsFor(l);
    final body = switch (tab) {
      0 => const _Overview(),
      1 => const _Bookings(),
      2 => const _Payments(),
      3 => _Users(canChangeRole: isAdmin),
      4 => const _Reviews(),
      _ => const _Content(),
    };
    final wide = isWide(context);
    return StatusTone.light(
      child: Scaffold(
        backgroundColor: Tokens.pageBg,
        body: Column(
          children: [
            _PortalHeader(
              title: l.administration,
              subtitle: l.administrationSub,
              roleLabel: isAdmin ? l.roleAdmin : l.roleStaff,
              icon: Icons.admin_panel_settings_outlined,
            ),
            if (!wide)
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  itemCount: tabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => WChip(
                    tabs[i].$1,
                    icon: tabs[i].$2,
                    selected: tab == i,
                    onTap: () => setState(() => tab = i),
                  ),
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wide)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                      decoration: BoxDecoration(
                        color: Tokens.surface,
                        borderRadius: BorderRadius.circular(Tokens.radius),
                        border: Border.all(color: Tokens.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Tokens.radius),
                        child: NavigationRail(
                          backgroundColor: Tokens.surface,
                          indicatorColor: Tokens.tint,
                          selectedIconTheme: const IconThemeData(
                            color: Tokens.primaryText,
                          ),
                          unselectedIconTheme: const IconThemeData(
                            color: Tokens.inkMuted,
                          ),
                          selectedLabelTextStyle: Type.body(
                            12,
                            weight: FontWeight.w700,
                            color: Tokens.primaryText,
                          ),
                          unselectedLabelTextStyle: Type.body(
                            12,
                            weight: FontWeight.w600,
                            color: Tokens.inkMuted,
                          ),
                          selectedIndex: tab,
                          onDestinationSelected: (i) => setState(() => tab = i),
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            for (final t in tabs)
                              NavigationRailDestination(
                                icon: Icon(t.$2),
                                label: Text(t.$1),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page<T> extends StatelessWidget {
  const _Page({
    required this.title,
    required this.child,
    this.actions = const [],
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(top: 6, bottom: 40),
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: Type.display(24))),
          ...actions,
        ],
      ),
      const SizedBox(height: 16),
      child,
    ],
  );
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.total,
    required this.size,
    required this.onPage,
  });
  final int page, total, size;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) {
    final pages = (total / size).ceil().clamp(1, 9999);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            context.l10n.totalCount(total),
            style: Type.body(13, color: Tokens.inkMuted),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: context.l10n.previousPage,
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Tokens.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Tokens.border),
            ),
            child: Text(
              '$page / $pages',
              style: Type.body(13, weight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: context.l10n.nextPage,
            onPressed: page < pages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

typedef _Loader = Future<Json> Function(int page);

/// Generic paginated list backed by an admin endpoint.
class _PagedList extends ConsumerStatefulWidget {
  const _PagedList({required this.load, required this.row, this.reloadKey});
  final _Loader load;
  final Widget Function(BuildContext, Json, VoidCallback reload) row;
  final Object? reloadKey;
  @override
  ConsumerState<_PagedList> createState() => _PagedListState();
}

class _PagedListState extends ConsumerState<_PagedList> {
  int page = 1;
  Future<Json>? _f;

  @override
  void initState() {
    super.initState();
    _f = widget.load(page);
  }

  @override
  void didUpdateWidget(covariant _PagedList old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey) {
      page = 1;
      _reload();
    }
  }

  void _reload() => setState(() => _f = widget.load(page));

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: _f,
    builder: (c, s) {
      if (s.connectionState != ConnectionState.done) {
        return const SkeletonList(count: 4, itemHeight: 72);
      }
      if (s.hasError) return ErrorState(error: s.error!, onRetry: _reload);
      final r = s.data!;
      final items = (r['items'] as List).cast<Json>();
      return Column(
        children: [
          if (items.isEmpty)
            EmptyState(title: context.l10n.nothingHereYet)
          else
            for (final it in items) widget.row(c, it, _reload),
          const SizedBox(height: 8),
          _Pager(
            page: page,
            total: (r['total'] ?? items.length) as int,
            size: (r['pageSize'] ?? 20) as int,
            onPage: (p) => setState(() {
              page = p;
              _f = widget.load(p);
            }),
          ),
        ],
      );
    },
  );
}

class _Overview extends ConsumerWidget {
  const _Overview();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);
    return _Page<void>(
      title: context.l10n.adminOverview,
      child: FutureBuilder<Json>(
        future: api.getJson('/admin/overview'),
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return const SkeletonList(count: 2);
          }
          if (s.hasError) return ErrorState(error: s.error!);
          final o = s.data!;
          final counts = (o['counts'] as Map).cast<String, dynamic>();
          final by = (o['bookingsByStatus'] as List).cast<Json>();
          final rev = (o['revenueSimulatedUsd'] as Map);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final e in counts.entries)
                    _Stat(e.key.replaceAll('_', ' '), '${e.value}'),
                  _Stat(
                    context.l10n.simulatedNetRevenue,
                    '\$${(rev['usd'] as num).toStringAsFixed(2)}',
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                o['note'] as String,
                style: Type.body(12, color: Tokens.inkMuted),
              ),
              SectionHeader(context.l10n.bookingsByStatus),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Tokens.surface,
                  borderRadius: BorderRadius.circular(Tokens.radius),
                  border: Border.all(color: Tokens.border),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final b in by)
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                        decoration: BoxDecoration(
                          color: Tokens.pageBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Tokens.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusPill(b['status'] as String),
                            const SizedBox(width: 8),
                            Text(
                              '${b['count']}',
                              style: Type.body(13.5, weight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.highlight = false});
  final String label, value;
  final bool highlight;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 168,
    child: Container(
      decoration: BoxDecoration(
        color: highlight ? Tokens.tint : Tokens.surface,
        borderRadius: BorderRadius.circular(Tokens.radius),
        border: Border.all(
          color: highlight
              ? Tokens.primary.withValues(alpha: 0.3)
              : Tokens.border,
        ),
        boxShadow: Tokens.softShadow(0.04),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3.5,
            decoration: const BoxDecoration(gradient: Tokens.sunrise),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Type.display(
                    26,
                    color: highlight ? Tokens.primaryText : Tokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: Type.label(11, color: Tokens.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Bookings extends ConsumerStatefulWidget {
  const _Bookings();
  @override
  ConsumerState<_Bookings> createState() => _BookingsState();
}

class _BookingsState extends ConsumerState<_Bookings> {
  String? status;
  String q = '';
  final _c = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiProvider);
    final money = ref.watch(moneyProvider);
    return _Page<void>(
      title: context.l10n.adminBookings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            decoration: InputDecoration(
              hintText: context.l10n.searchBookingsHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: q.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _c.clear();
                        setState(() => q = '');
                      },
                    )
                  : null,
            ),
            onSubmitted: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                WChip(
                  context.l10n.all,
                  selected: status == null,
                  onTap: () => setState(() => status = null),
                ),
                for (final s in const [
                  'PENDING_CONFIRMATION',
                  'CONFIRMED',
                  'CHECKED_IN',
                  'COMPLETED',
                  'CANCELLED',
                  'REFUNDED',
                  'EXPIRED',
                ]) ...[
                  const SizedBox(width: 8),
                  WChip(
                    statusLabel(context.l10n, s),
                    selected: status == s,
                    onTap: () =>
                        setState(() => status = status == s ? null : s),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PagedList(
            reloadKey: '$status|$q',
            load: (p) => api.getJson(
              '/admin/bookings',
              query: {'page': p, 'status': status, 'q': q},
            ),
            row: (c, b, reload) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Tokens.surface,
                borderRadius: BorderRadius.circular(Tokens.radius),
                border: Border.all(color: Tokens.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Tokens.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: Tokens.primary,
                  ),
                ),
                title: Text(
                  '${b['reference']} · ${b['guest_name']}',
                  style: Type.body(15, weight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${b['accommodation_name']}\n${fmtDate(b['check_in'] as String)} → ${fmtDate(b['check_out'] as String)} · ${money(b['total_usd'] as num)}',
                  style: Type.body(12.5, color: Tokens.inkMuted, height: 1.4),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusPill(b['status'] as String),
                    PopupMenuButton<String>(
                      tooltip: c.l10n.actions,
                      onSelected: (a) async {
                        try {
                          if (a == 'cancel') {
                            final ok = await confirm(
                              c,
                              title: c.l10n.cancelBookingRef(
                                '${b['reference']}',
                              ),
                              message: c.l10n.adminCancelBody,
                              confirmLabel: c.l10n.cancelBooking,
                              destructive: true,
                            );
                            if (!ok) return;
                            await api.postJson(
                              '/admin/bookings/${b['id']}/cancel',
                            );
                          } else {
                            await api.postJson(
                              '/admin/bookings/${b['id']}/transition',
                              body: {'to': a},
                            );
                          }
                          reload();
                        } catch (e) {
                          if (c.mounted) showError(c, e);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'CHECKED_IN',
                          child: Text(c.l10n.markCheckedIn),
                        ),
                        PopupMenuItem(
                          value: 'COMPLETED',
                          child: Text(c.l10n.markCompleted),
                        ),
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text(c.l10n.cancelBooking),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => showDialog<void>(
                  context: c,
                  builder: (d) => _BookingDialog(id: b['id'] as String),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDialog extends ConsumerWidget {
  const _BookingDialog({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(context.l10n.bookingDetail),
      content: SizedBox(
        width: 460,
        child: FutureBuilder<Json>(
          future: ref.read(apiProvider).getJson('/admin/bookings/$id'),
          builder: (c, s) {
            if (s.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (s.hasError) return ErrorState(error: s.error!);
            final b = s.data!;
            final ev = (b['events'] as List).cast<Json>();
            final pay = (b['payments'] as List).cast<Json>();
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${b['reference']} · ${b['accommodation_name']}',
                    style: Type.body(15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${b['guest_name']} · ${b['guest_email']}',
                    style: Type.body(13.5, color: Tokens.inkSoft),
                  ),
                  Text(
                    '${b['check_in']} → ${b['check_out']} · ${context.l10n.nightsCount(b['nights'] as int)} · \$${b['total_usd']}',
                    style: Type.body(13.5, color: Tokens.inkMuted),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.statusHistory,
                    style: Type.body(14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  for (final e in ev)
                    Text(
                      '• ${statusLabel(context.l10n, e['to_status'] as String)} — ${fmtDate(e['created_at'] as String, pattern: 'd MMM y HH:mm')}${e['note'] != null ? ' (${e['note']})' : ''}',
                      style: Type.body(13, color: Tokens.inkSoft),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.payments,
                    style: Type.body(14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  for (final p in pay)
                    Text(
                      '• ${statusLabel(context.l10n, p['status'] as String)} \$${p['amount_usd']} ${p['provider_ref']}',
                      style: Type.body(13, color: Tokens.inkSoft),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.close),
        ),
      ],
    );
  }
}

class _Payments extends ConsumerWidget {
  const _Payments();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);
    return _Page<void>(
      title: context.l10n.paymentsAndTransactions,
      child: _PagedList(
        load: (p) => api.getJson('/admin/payments', query: {'page': p}),
        row: (c, p, _) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Tokens.surface,
            borderRadius: BorderRadius.circular(Tokens.radius),
            border: Border.all(color: Tokens.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Tokens.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.payments_outlined, color: Tokens.primary),
            ),
            title: Text(
              '\$${p['amount_usd']} · ${p['reference']}',
              style: Type.body(15, weight: FontWeight.w700),
            ),
            subtitle: Text(
              '${p['provider_ref']} · ${p['provider']}${p['failure_reason'] != null ? ' · ${p['failure_reason']}' : ''}',
              style: Type.body(12.5, color: Tokens.inkMuted),
            ),
            trailing: StatusPill(p['status'] as String),
          ),
        ),
      ),
    );
  }
}

class _Users extends ConsumerStatefulWidget {
  const _Users({required this.canChangeRole});
  final bool canChangeRole;
  @override
  ConsumerState<_Users> createState() => _UsersState();
}

class _UsersState extends ConsumerState<_Users> {
  String q = '';
  String? role;
  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiProvider);
    return _Page<void>(
      title: context.l10n.adminUsers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: context.l10n.nameOrEmail,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                WChip(
                  context.l10n.all,
                  selected: role == null,
                  onTap: () => setState(() => role = null),
                ),
                for (final r in const [
                  'customer',
                  'partner',
                  'staff',
                  'admin',
                ]) ...[
                  const SizedBox(width: 8),
                  WChip(
                    capitalize(r),
                    selected: role == r,
                    onTap: () => setState(() => role = role == r ? null : r),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PagedList(
            reloadKey: '$q|$role',
            load: (p) => api.getJson(
              '/admin/users',
              query: {'page': p, 'q': q, 'role': role},
            ),
            row: (c, u, reload) {
              final name = (u['name'] as String?) ?? '';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Tokens.surface,
                  borderRadius: BorderRadius.circular(Tokens.radius),
                  border: Border.all(color: Tokens.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: Tokens.sunrise,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: Type.display(18, color: Colors.white),
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: Type.body(15, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${u['email']}',
                    style: Type.body(12.5, color: Tokens.inkMuted),
                  ),
                  trailing: widget.canChangeRole
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Tokens.pageBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Tokens.border),
                          ),
                          child: DropdownButton<String>(
                            value: u['role'] as String,
                            underline: const SizedBox.shrink(),
                            style: Type.body(
                              13,
                              weight: FontWeight.w700,
                              color: Tokens.primaryText,
                            ),
                            items: [
                              for (final r in [
                                'customer',
                                'partner',
                                'staff',
                                'admin',
                              ])
                                DropdownMenuItem(value: r, child: Text(r)),
                            ],
                            onChanged: (v) async {
                              if (v == null || v == u['role']) return;
                              final ok = await confirm(
                                c,
                                title: c.l10n.changeRoleQ,
                                message: c.l10n.changeRoleBody(
                                  '${u['email']}',
                                  v,
                                ),
                                confirmLabel: c.l10n.changeRole,
                              );
                              if (!ok) return;
                              try {
                                await api.patchEmpty(
                                  '/admin/users/${u['id']}/role',
                                  body: {'role': v},
                                );
                                reload();
                              } catch (e) {
                                if (c.mounted) showError(c, e);
                              }
                            },
                          ),
                        )
                      : Pill(u['role'] as String),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Reviews extends ConsumerWidget {
  const _Reviews();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);
    return _Page<void>(
      title: context.l10n.reviewModeration,
      child: _PagedList(
        load: (p) => api.getJson('/admin/reviews', query: {'page': p}),
        row: (c, r, reload) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Tokens.surface,
            borderRadius: BorderRadius.circular(Tokens.radius),
            border: Border.all(color: Tokens.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              children: [
                StarRow(r['rating'] as int, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${r['title']}',
                    style: Type.body(15, weight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${r['accommodation_name']} · ${r['author']}\n${r['body']}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Type.body(12.5, color: Tokens.inkMuted, height: 1.4),
              ),
            ),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: () async {
                final next = r['status'] == 'published'
                    ? 'hidden'
                    : 'published';
                try {
                  await api.patchEmpty(
                    '/admin/reviews/${r['id']}',
                    body: {'status': next},
                  );
                  reload();
                } catch (e) {
                  if (c.mounted) showError(c, e);
                }
              },
              child: Text(
                r['status'] == 'published'
                    ? context.l10n.hide
                    : context.l10n.publish,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content();
  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _country = TextEditingController(text: 'Cambodia');
  final _short = TextEditingController(), _long = TextEditingController();
  final _lat = TextEditingController(),
      _lng = TextEditingController(),
      _budget = TextEditingController(text: '40');
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    String? req(String? v) =>
        (v ?? '').trim().isEmpty ? context.l10n.required : null;
    String? num_(String? v, double lo, double hi) {
      final d = double.tryParse((v ?? '').trim());
      return d == null || d < lo || d > hi
          ? context.l10n.numberBetween('$lo', '$hi')
          : null;
    }

    return _Page<void>(
      title: context.l10n.createDestination,
      child: Form(
        key: _form,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Tokens.surface,
              borderRadius: BorderRadius.circular(Tokens.radius),
              border: Border.all(color: Tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: context.l10n.name),
                  validator: (v) => (v ?? '').trim().length < 2
                      ? context.l10n.atLeast2Chars
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _country,
                  decoration: InputDecoration(labelText: context.l10n.country),
                  validator: req,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _short,
                  decoration: InputDecoration(
                    labelText: context.l10n.shortDescription,
                  ),
                  validator: (v) => (v ?? '').trim().length < 10
                      ? context.l10n.atLeast10CharsShort
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _long,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.l10n.longDescription,
                  ),
                  validator: (v) => (v ?? '').trim().length < 20
                      ? context.l10n.atLeast20Chars
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        decoration: InputDecoration(
                          labelText: context.l10n.latitude,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) => num_(v, -90, 90),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lng,
                        decoration: InputDecoration(
                          labelText: context.l10n.longitude,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) => num_(v, -180, 180),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budget,
                  decoration: InputDecoration(
                    labelText: context.l10n.dailyBudgetUsd,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => num_(v, 0, 5000),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (!_form.currentState!.validate()) return;
                            setState(() => busy = true);
                            try {
                              final createdName = _name.text.trim();
                              final createdCountry = _country.text.trim();
                              final createdBudget = double.parse(_budget.text);
                              await ref
                                  .read(apiProvider)
                                  .postJson(
                                    '/admin/destinations',
                                    body: {
                                      'name': createdName,
                                      'country': createdCountry,
                                      'shortDescription': _short.text.trim(),
                                      'longDescription': _long.text.trim(),
                                      'lat': double.parse(_lat.text),
                                      'lng': double.parse(_lng.text),
                                      'dailyBudgetUsd': createdBudget,
                                      'currency': 'USD',
                                    },
                                  );
                              if (context.mounted) {
                                _form.currentState!.reset();
                                ref.invalidate(metaProvider);
                                await _showSuccessDialog(
                                  context,
                                  title: context.l10n.destinationCreated,
                                  message:
                                      '$createdName ($createdCountry) is now published in the destinations catalog.',
                                  details: [
                                    (context.l10n.name, createdName),
                                    (context.l10n.country, createdCountry),
                                    (
                                      context.l10n.dailyBudgetUsd,
                                      '\$${createdBudget.toStringAsFixed(0)} / day',
                                    ),
                                  ],
                                );
                              }
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                            if (mounted) setState(() => busy = false);
                          },
                    child: Text(context.l10n.createDestination),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.adminHotelsNote,
                  style: Type.body(12, color: Tokens.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------------------------------------------- partner portal */

class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});
  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  int version = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final l = context.l10n;
    if (!auth.isPartner) {
      return Scaffold(
        backgroundColor: Tokens.pageBg,
        body: Column(
          children: [
            _PortalHeader(
              title: l.partnerPortal,
              subtitle: l.partnerPortalSub,
              roleLabel: l.rolePartner,
              icon: Icons.storefront_outlined,
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.lock_outline_rounded,
                title: l.partnerAccessRequired,
                message: l.partnerAccessHint,
              ),
            ),
          ],
        ),
      );
    }
    final api = ref.watch(apiProvider);
    final money = ref.watch(moneyProvider);
    return StatusTone.light(
      child: Scaffold(
        backgroundColor: Tokens.pageBg,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _PortalHeader(
              title: l.partnerPortal,
              subtitle: l.partnerPortalSub,
              roleLabel: l.rolePartner,
              icon: Icons.storefront_outlined,
            ),
            Constrained(
              maxWidth: 1000,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<Json>(
                      key: ValueKey('an$version'),
                      future: api.getJson('/partner/analytics'),
                      builder: (c, s) {
                        if (!s.hasData) return const SizedBox.shrink();
                        final a = s.data!;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _Stat(
                              l.occupancyNext30,
                              a['occupancyPctNext30Days'] == null
                                  ? l.notApplicable
                                  : '${a['occupancyPctNext30Days']}%',
                              highlight: true,
                            ),
                            for (final b
                                in (a['bookingsByStatus'] as List).cast<Json>())
                              _Stat(
                                statusLabel(l, b['status'] as String),
                                '${b['count']}',
                              ),
                          ],
                        );
                      },
                    ),
                    SectionHeader(l.yourProperties),
                    FutureBuilder<Json>(
                      key: ValueKey('pr$version'),
                      future: api.getJson('/partner/accommodations'),
                      builder: (c, s) {
                        if (s.connectionState != ConnectionState.done) {
                          return const SkeletonList(count: 2);
                        }
                        if (s.hasError) return ErrorState(error: s.error!);
                        final items = (s.data!['items'] as List).cast<Json>();
                        if (items.isEmpty) {
                          return EmptyState(title: l.noPropertiesAssigned);
                        }
                        return Column(
                          children: [
                            for (final p in items)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Tokens.surface,
                                  borderRadius: BorderRadius.circular(
                                    Tokens.radius,
                                  ),
                                  border: Border.all(color: Tokens.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Tokens.tint,
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.hotel_rounded,
                                            color: Tokens.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            p['name'] as String,
                                            style: Type.display(19),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    for (final r
                                        in ((p['rooms'] as List?) ?? const [])
                                            .cast<Json>())
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Tokens.pageBg,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: Tokens.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    r['name'] as String,
                                                    style: Type.body(
                                                      14.5,
                                                      weight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  Text(
                                                    l.baseRooms(
                                                      money(
                                                        r['base_price_usd']
                                                            as num,
                                                      ),
                                                      '${r['total_units']}',
                                                    ),
                                                    style: Type.body(
                                                      12.5,
                                                      color: Tokens.inkMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: const Size(0, 40),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                    ),
                                              ),
                                              onPressed: () =>
                                                  _editInventory(context, r),
                                              child: Text(l.availability),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SectionHeader(l.incomingBookings),
                    _PagedList(
                      reloadKey: version,
                      load: (p) =>
                          api.getJson('/partner/bookings', query: {'page': p}),
                      row: (c, b, reload) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Tokens.surface,
                          borderRadius: BorderRadius.circular(Tokens.radius),
                          border: Border.all(color: Tokens.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Tokens.tint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.luggage_outlined,
                              color: Tokens.primary,
                            ),
                          ),
                          title: Text(
                            '${b['reference']} · ${b['guest_name']}',
                            style: Type.body(15, weight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${b['accommodation_name']} · ${b['room_name']}\n${fmtDate(b['check_in'] as String)} → ${fmtDate(b['check_out'] as String)}',
                            style: Type.body(
                              12.5,
                              color: Tokens.inkMuted,
                              height: 1.4,
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusPill(b['status'] as String),
                              if (b['status'] == 'CONFIRMED')
                                TextButton(
                                  onPressed: () =>
                                      _t(c, b, 'CHECKED_IN', reload),
                                  child: Text(c.l10n.checkInAction),
                                ),
                              if (b['status'] == 'CHECKED_IN')
                                TextButton(
                                  onPressed: () =>
                                      _t(c, b, 'COMPLETED', reload),
                                  child: Text(c.l10n.complete),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _t(
    BuildContext c,
    Json b,
    String to,
    VoidCallback reload,
  ) async {
    try {
      await ref
          .read(apiProvider)
          .postJson(
            '/partner/bookings/${b['id']}/transition',
            body: {'to': to},
          );
      reload();
      setState(() => version++);
      if (c.mounted) {
        await _showSuccessDialog(
          c,
          title: statusLabel(c.l10n, to),
          message:
              'Booking ${b['reference']} for ${b['guest_name']} has been updated.',
          details: [
            ('Reference', '${b['reference']}'),
            ('Guest', '${b['guest_name']}'),
            ('Status', statusLabel(c.l10n, to)),
          ],
        );
      }
    } catch (e) {
      if (c.mounted) showError(c, e);
    }
  }

  Future<void> _editInventory(BuildContext context, Json room) async {
    final formKey = GlobalKey<FormState>();
    final maxUnits = (room['total_units'] as num?)?.toInt() ?? 200;
    final basePrice = (room['base_price_usd'] as num?)?.toDouble() ?? 0;
    final units = TextEditingController(text: '$maxUnits');
    final price = TextEditingController();
    final now = DateTime.now();
    DateTimeRange range = DateTimeRange(
      start: now.add(const Duration(days: 1)),
      end: now.add(const Duration(days: 14)),
    );
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          final nights = (range.end.difference(range.start).inDays + 1).clamp(
            1,
            366,
          );
          final uVal = int.tryParse(units.text.trim()) ?? 0;
          final pVal = double.tryParse(price.text.trim()) ?? basePrice;
          final maxRev = nights * uVal * pVal;
          return AlertDialog(
            title: Text(context.l10n.availabilityFor('${room['name']}')),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text('${iso(range.start)} → ${iso(range.end)}'),
                    onPressed: () async {
                      final r = await showDateRangePicker(
                        context: c,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        initialDateRange: range,
                      );
                      if (r != null) set(() => range = r);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: units,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.roomsAvailablePerNight(
                        '$maxUnits',
                      ),
                    ),
                    onChanged: (_) => set(() {}),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 0 || n > maxUnits) {
                        return context.l10n.numberBetween('0', '$maxUnits');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.nightlyPriceOptional,
                    ),
                    onChanged: (_) => set(() {}),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      final d = double.tryParse(s);
                      if (d == null || d < 1 || d > 10000) {
                        return context.l10n.numberBetween('1', '10000');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Tokens.tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$nights nights · ${nights * uVal} room-nights · \$${maxRev.toStringAsFixed(0)} max capacity',
                      style: Type.body(
                        12.5,
                        weight: FontWeight.w700,
                        color: Tokens.primaryText,
                      ),
                    ),
                  ),
                ],
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
                    final savedUnits = int.parse(units.text.trim());
                    final savedPrice = price.text.trim().isNotEmpty
                        ? double.parse(price.text.trim())
                        : null;
                    await ref
                        .read(apiProvider)
                        .putJson(
                          '/partner/room-types/${room['id']}/inventory',
                          body: {
                            'from': iso(range.start),
                            'to': iso(range.end),
                            'units': savedUnits,
                            'priceUsd': ?savedPrice,
                          },
                        );
                    if (c.mounted) Navigator.pop(c);
                    if (context.mounted) {
                      setState(() => version++);
                      await _showSuccessDialog(
                        context,
                        title: context.l10n.availabilityUpdated,
                        message:
                            '${room['name']} inventory has been updated for $nights nights.',
                        details: [
                          ('Room', '${room['name']}'),
                          (
                            'Date range',
                            '${iso(range.start)} → ${iso(range.end)}',
                          ),
                          ('Units / night', '$savedUnits / $maxUnits'),
                          (
                            'Nightly rate',
                            savedPrice != null
                                ? '\$${savedPrice.toStringAsFixed(2)}'
                                : '\$${basePrice.toStringAsFixed(2)} (base)',
                          ),
                        ],
                      );
                    }
                  } catch (e) {
                    if (c.mounted) showError(c, e);
                  }
                },
                child: Text(context.l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

void goAdmin(BuildContext c) => c.go('/admin');
