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
import '../maps/place_map.dart';

/// Trips tab: the planner entry point, the user's saved trips and curated journeys.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider).signedIn;
    final mine = signedIn ? ref.watch(itinerariesProvider) : null;
    final home = ref.watch(homeProvider);
    final money = ref.watch(moneyProvider);
    final top = MediaQuery.paddingOf(context).top;

    return ToneOnScroll(child: RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(itinerariesProvider);
        ref.invalidate(homeProvider);
      },
      child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
            decoration: const BoxDecoration(gradient: Tokens.dusk, borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TRIPS', style: Type.label(11, color: Tokens.gold)),
              const SizedBox(height: 6),
              Text('Tell us where.\nWe build the days.', style: Type.display(34, color: Colors.white, height: 1.04)),
              const SizedBox(height: 20),
              Pressable(
                onTap: () => context.push('/trips/new'),
                radius: 24,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(24), boxShadow: Tokens.softShadow(0.25)),
                  child: Row(children: [
                    Container(width: 52, height: 52, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFF0B85A), Tokens.terracotta])), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Plan with AI', style: Type.display(21)),
                        const SizedBox(height: 2),
                        Text('"3 days in Kampot, relaxed, two kids"', style: Type.body(12.5, color: Tokens.inkMuted, height: 1.3), maxLines: 2),
                      ]),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Tokens.forest),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: SectionTitle('Your trips', eyebrow: 'Saved', action: signedIn ? 'New' : null, onAction: () => context.push('/trips/new'))),
        SliverToBoxAdapter(
          child: !signedIn
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(24), border: Border.all(color: Tokens.border)),
                    child: Row(children: [
                      const Icon(Icons.lock_outline_rounded, color: Tokens.forest),
                      const SizedBox(width: 14),
                      Expanded(child: Text('Sign in to save itineraries and edit them any time.', style: Type.body(14, color: Tokens.inkSoft, height: 1.4))),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: () => context.push('/login?next=%2Ftrips'), style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), child: const Text('Sign in')),
                    ]),
                  ),
                )
              : mine!.when(
                  loading: () => const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonList(count: 2, itemHeight: 110)),
                  error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(itinerariesProvider)),
                  data: (r) {
                    final items = (r['items'] as List).cast<Json>();
                    if (items.isEmpty) {
                      return EmptyState(icon: Icons.map_outlined, title: 'No saved trips yet', message: 'Describe your trip to the planner and save the plan here.', action: FilledButton(onPressed: () => context.push('/trips/new'), child: const Text('Start planning')));
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [for (final (i, it) in items.indexed) Padding(padding: const EdgeInsets.only(bottom: 14), child: Reveal(delay: Duration(milliseconds: 50 * i), child: _TripRow(trip: it, money: money)))]),
                    );
                  },
                ),
        ),
        const SliverToBoxAdapter(child: SectionTitle('Curated journeys', eyebrow: 'Start from one')),
        SliverToBoxAdapter(
          child: home.when(
            loading: () => const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonList(count: 2, itemHeight: 110)),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(homeProvider)),
            data: (h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [for (final it in (h['itineraries'] as List).cast<Json>()) Padding(padding: const EdgeInsets.only(bottom: 14), child: _TripRow(trip: it, money: money, curated: true))]),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: dockClearance(context))),
      ]),
    ));
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.money, this.curated = false});
  final Json trip;
  final String Function(num) money;
  final bool curated;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => context.push('/trips/${trip['id']}'),
        child: Container(
          height: 118,
          decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(24), border: Border.all(color: Tokens.border), boxShadow: Tokens.softShadow(0.06)),
          child: Row(children: [
            ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)), child: SizedBox(width: 112, height: 118, child: WImage(trip['cover_image'] as String?, width: 112, height: 118))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${trip['destination_name']} · ${trip['num_days']} DAY${trip['num_days'] == 1 ? '' : 'S'}'.toUpperCase(), style: Type.label(10, color: Tokens.terracotta)),
                  const SizedBox(height: 5),
                  Text(trip['title'] as String, style: Type.display(18, height: 1.12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('Est. ${money(trip['est_total_usd'] as num)}${curated ? '' : ' · ${trip['generated_by'] == 'rules' ? 'Rules planner' : trip['generated_by'] == 'llm' ? 'AI-assisted' : 'Manual'}'}', style: Type.body(12, color: Tokens.inkMuted, weight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
      );
}

/// Natural-language trip planner. Shows the understood parameters, asks for missing info, never invents places.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key, this.destination});
  final String? destination;
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final _prompt = TextEditingController();
  final _scroll = ScrollController();
  bool busy = false;
  Json? result;
  Object? error;

  static const examples = [
    ('Slow Kampot weekend', 'A relaxed weekend in Kampot, riverside and local dining'),
    ('Angkor for photographers', 'Four days in Siem Reap for 2 adults, temples and photography'),
    ('Phnom Penh on \$150', 'I have three days in Phnom Penh, two adults, and a total budget of \$150. I enjoy Khmer food, culture, photography and relaxed walks.'),
    ('Singapore with kids', '3 days in Singapore with 2 adults and 2 kids'),
    ('Kyoto temples', '4 days in Kyoto for 2 adults, temples and culture'),
    ('Hoi An food trip', '3 days in Hoi An, food and relaxed walks'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.destination != null) {
      _prompt.text = '3 days in ${widget.destination!.split('-').map(capitalize).join(' ')} for 2 adults';
    }
  }

  @override
  void dispose() {
    _prompt.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _generate({bool save = false}) async {
    if (_prompt.text.trim().length < 5) return;
    FocusScope.of(context).unfocus();
    tick();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await ref.read(apiProvider).postJson('/ai/travel-plan', body: {'prompt': _prompt.text.trim(), 'save': save});
      if (save && r['itineraryId'] != null && mounted) {
        ref.invalidate(itinerariesProvider);
        context.go('/trips/${r['itineraryId']}');
        return;
      }
      setState(() => result = r);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(380, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
      });
    } catch (e) {
      setState(() => error = e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authProvider).signedIn;
    final status = ref.watch(aiStatusProvider).value;
    return Scaffold(
      body: ToneOnScroll(child: ListView(controller: _scroll, padding: EdgeInsets.zero, children: [
        Container(
          padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 6, 20, 24),
          decoration: const BoxDecoration(gradient: Tokens.dusk, borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButton(tooltip: 'Back', onPressed: () => context.canPop() ? context.pop() : context.go('/trips'), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI TRIP PLANNER', style: Type.label(11, color: Tokens.gold)),
                const SizedBox(height: 6),
                Text('Describe the trip\nyou want.', style: Type.display(34, color: Colors.white, height: 1.04)),
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(status['llmConfigured'] == true ? Icons.auto_awesome_rounded : Icons.rule_rounded, size: 15, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(child: Text(status['llmConfigured'] == true ? 'Language-model assisted, grounded in stored places' : 'Built on stored places by a rules engine. Fast and never invents.', style: Type.body(12, color: Colors.white70))),
                  ]),
                ],
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(24), border: Border.all(color: Tokens.border), boxShadow: Tokens.softShadow(0.06)),
              child: TextField(
                controller: _prompt,
                minLines: 3,
                maxLines: 6,
                maxLength: 800,
                style: Type.body(16, height: 1.5),
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => Text('$currentLength / $maxLength', style: Type.body(11, color: Tokens.inkMuted)),
                decoration: InputDecoration(hintText: 'e.g. 3 days in Phnom Penh, 2 adults, \$150 total, love food and culture', hintStyle: Type.body(15, color: Tokens.inkMuted), filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: examples.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => WChip(examples[i].$1, icon: Icons.bolt_rounded, onTap: () => setState(() => _prompt.text = examples[i].$2)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : _generate,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 60), backgroundColor: Tokens.terracotta),
                icon: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded),
                label: Text(busy ? 'Planning your days…' : 'Create itinerary'),
              ),
            ),
            if (error != null) ErrorState(error: error!, onRetry: _generate),
            if (busy && result == null) const Padding(padding: EdgeInsets.only(top: 24), child: SkeletonList(count: 2, itemHeight: 140)),
            if (result != null) ...[
              const SizedBox(height: 26),
              _ResultView(
                result: result!,
                signedIn: signedIn,
                onSave: () {
                  if (!signedIn) {
                    context.push('/login?next=${Uri.encodeComponent('/trips/new')}');
                  } else {
                    _generate(save: true);
                  }
                },
              ),
            ],
            const SizedBox(height: 60),
          ]),
        ),
      ])),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onSave, required this.signedIn});
  final Json result;
  final VoidCallback onSave;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    if (result['status'] == 'needs_more_info') {
      final qs = (result['questions'] as List).cast<String>();
      final dests = (result['availableDestinations'] as List).cast<Json>();
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(24), border: Border.all(color: Tokens.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('A little more detail, please', style: Type.display(22)),
          const SizedBox(height: 10),
          for (final q in qs) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $q', style: Type.body(14.5))),
          const SizedBox(height: 14),
          Text('DESTINATIONS I CAN PLAN', style: Type.label(10.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final d in dests) Pill(d['name'] as String, color: Tokens.forest)]),
        ]),
      );
    }
    final plan = result['plan'] as Json;
    final understood = result['understood'] as Json;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Tokens.sand, borderRadius: BorderRadius.circular(20)),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('I understood', style: Type.body(13, weight: FontWeight.w800)),
          Pill('${understood['days']} days', icon: Icons.calendar_today_outlined),
          Pill('${understood['adults']} adults${(understood['children'] as int) > 0 ? ', ${understood['children']} children' : ''}', icon: Icons.people_outline),
          if (understood['budgetUsd'] != null) Pill('\$${understood['budgetUsd']} ${understood['budgetIsPerDay'] == true ? 'per day' : 'total'}', icon: Icons.payments_outlined),
          for (final i in (understood['interests'] as List).cast<String>()) Pill(i, color: Tokens.terracotta),
        ]),
      ),
      if (result['parserNote'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(result['parserNote'] as String, style: Type.body(12, color: Tokens.inkMuted))),
      const SizedBox(height: 18),
      PlanView(plan: plan),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.bookmark_add_outlined), label: Text(signedIn ? 'Save to my trips' : 'Sign in to save this trip'))),
    ]);
  }
}

/// Renders a plan or loaded itinerary: summary and budget split, a day picker and a vertical stop timeline.
class PlanView extends ConsumerStatefulWidget {
  const PlanView({super.key, required this.plan, this.editing = false, this.onRemove, this.onMove, this.onRegenerate});
  final Json plan;
  final bool editing;
  final void Function(int day, int index)? onRemove;
  final void Function(int day, int from, int to)? onMove;
  final void Function(int day)? onRegenerate;

  @override
  ConsumerState<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends ConsumerState<PlanView> {
  int _day = 0;
  bool _map = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final money = ref.watch(moneyProvider);
    final days = (plan['days'] as List).cast<Json>();
    final budget = plan['budget'] as Json?;
    final warnings = ((plan['warnings'] as List?) ?? const []).cast<String>();
    final assumptions = ((plan['assumptions'] as List?) ?? const []).map((e) => e.toString()).toList();
    final day = days.isEmpty ? null : days[_day.clamp(0, days.length - 1)];
    final items = day == null ? <Json>[] : (day['items'] as List).cast<Json>();
    final dayNo = day?['day'] as int? ?? 1;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (plan['title'] != null) Text(plan['title'] as String, style: Type.display(28, height: 1.08)),
      if (plan['summary'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(plan['summary'] as String, style: Type.body(14.5, color: Tokens.inkSoft, height: 1.55))),
      if (plan['modeNote'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(plan['mode'] == 'llm' ? Icons.auto_awesome_rounded : Icons.rule_rounded, size: 15, color: Tokens.terracotta),
            const SizedBox(width: 6),
            Expanded(child: Text(plan['modeNote'] as String, style: Type.body(11.5, color: Tokens.terracotta, height: 1.4))),
          ]),
        ),
      for (final w in warnings)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Tokens.gold.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF7A5517)), const SizedBox(width: 10), Expanded(child: Text(w, style: Type.body(12.5, height: 1.45)))])),
        ),
      if (budget != null) ...[const SizedBox(height: 18), _BudgetCard(plan: plan, budget: budget, assumptions: assumptions, money: money)],
      if (days.isNotEmpty) ...[
        const SizedBox(height: 26),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => WChip('Day ${days[i]['day']}', selected: i == _day, onTap: () => setState(() { _day = i; _map = false; })),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text('${items.length} stop${items.length == 1 ? '' : 's'} · ${money(day!['costUsd'] as num? ?? 0)}', style: Type.body(13.5, weight: FontWeight.w700, color: Tokens.inkMuted))),
          if (items.isNotEmpty) TextButton.icon(onPressed: () => setState(() => _map = !_map), icon: Icon(_map ? Icons.view_timeline_outlined : Icons.map_outlined, size: 18), label: Text(_map ? 'Timeline' : 'Route map')),
          if (widget.editing && widget.onRegenerate != null) IconButton(tooltip: 'Regenerate day $dayNo', onPressed: () => widget.onRegenerate!(dayNo), icon: const Icon(Icons.autorenew_rounded)),
        ]),
        if (items.isEmpty) const EmptyState(icon: Icons.event_busy_outlined, title: 'No stops yet', message: 'This day has no suggestions.'),
        if (_map && items.isNotEmpty) ...[
          PlaceMap(height: 320, radius: 24, drawRoute: true, points: [for (final (i, it) in items.indexed) MapPoint(lat: (it['lat'] as num).toDouble(), lng: (it['lng'] as num).toDouble(), title: it['name'] as String, subtitle: fmtMinutes(it['startMin'] as int), index: i + 1)]),
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('The dashed line joins stops in order: straight lines, not driving directions.', style: Type.body(11, color: Tokens.inkMuted))),
        ] else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Column(
              key: ValueKey('$_day-${items.length}'),
              children: [
                for (final (i, it) in items.indexed)
                  _Stop(
                    index: i,
                    item: it,
                    last: i == items.length - 1,
                    money: money,
                    editing: widget.editing,
                    onUp: i > 0 && widget.onMove != null ? () => widget.onMove!(dayNo, i, i - 1) : null,
                    onDown: i < items.length - 1 && widget.onMove != null ? () => widget.onMove!(dayNo, i, i + 1) : null,
                    onRemove: widget.onRemove == null ? null : () => widget.onRemove!(dayNo, i),
                  ),
              ],
            ),
          ),
      ],
    ]);
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.plan, required this.budget, required this.assumptions, required this.money});
  final Json plan, budget;
  final List<String> assumptions;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) {
    final parts = [
      ('Stay', (budget['lodgingUsd'] as num).toDouble(), Tokens.forest),
      ('Activities', (budget['activitiesUsd'] as num).toDouble(), Tokens.terracotta),
      ('Food', (budget['foodUsd'] as num).toDouble(), Tokens.gold),
      ('Transport', (budget['transportUsd'] as num).toDouble(), Tokens.jade),
    ].where((p) => p.$2 > 0).toList();
    final total = (budget['totalUsd'] as num).toDouble();
    final within = budget['withinBudget'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(26), border: Border.all(color: Tokens.border), boxShadow: Tokens.softShadow(0.06)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ESTIMATED TOTAL', style: Type.label(10.5)),
        const SizedBox(height: 4),
        CountUp(value: total, builder: (v) => Text(money(v), style: Type.display(40, height: 1.05))),
        if (budget['budgetUsd'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(within == true ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 18, color: within == true ? Tokens.success : Tokens.danger),
              const SizedBox(width: 6),
              Text(within == true ? 'Within your ${money(budget['budgetUsd'] as num)} budget' : 'Over your ${money(budget['budgetUsd'] as num)} budget', style: Type.body(13, weight: FontWeight.w800, color: within == true ? Tokens.success : Tokens.danger)),
            ]),
          ),
        if (total > 0 && parts.length > 1) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(height: 12, child: Row(children: [for (final p in parts) Expanded(flex: (p.$2 / total * 1000).round().clamp(1, 1000), child: Container(color: p.$3))])),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 16, runSpacing: 8, children: [
            for (final p in parts)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${p.$1} ', style: Type.body(12.5, color: Tokens.inkMuted)),
                Text(money(p.$2), style: Type.body(12.5, weight: FontWeight.w800)),
              ]),
          ]),
        ],
        if (plan['lodging'] != null) ...[
          const SizedBox(height: 14),
          Row(children: [const Icon(Icons.bed_outlined, size: 17, color: Tokens.forest), const SizedBox(width: 8), Expanded(child: Text('${plan['lodging']['name']} · ${plan['lodging']['nights']} night${plan['lodging']['nights'] == 1 ? '' : 's'}', style: Type.body(13, weight: FontWeight.w600)))]),
        ],
        if (assumptions.isNotEmpty)
          Material(
            type: MaterialType.transparency,
            child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text('Assumptions', style: Type.body(13.5, weight: FontWeight.w700, color: Tokens.inkMuted)),
              children: [for (final a in assumptions) Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $a', style: Type.body(12.5, color: Tokens.inkMuted, height: 1.45))))],
            ),
          ),
          ),
      ]),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.index, required this.item, required this.last, required this.money, required this.editing, this.onUp, this.onDown, this.onRemove});
  final int index;
  final Json item;
  final bool last, editing;
  final String Function(num) money;
  final VoidCallback? onUp, onDown, onRemove;

  @override
  Widget build(BuildContext context) {
    final travel = ((item['travelMinFromPrev'] ?? 0) as num).toInt();
    final cost = (item['costUsd'] as num?) ?? 0;
    return Reveal(
      delay: Duration(milliseconds: 50 * index),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 66,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fmtMinutes(item['startMin'] as int).replaceAll(' ', ' '), style: Type.body(12.5, weight: FontWeight.w800)),
                Text('${item['durationMin']}m', style: Type.body(11, color: Tokens.inkMuted)),
              ]),
            ),
          ),
          Column(children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(gradient: Tokens.dusk, shape: BoxShape.circle),
              child: Center(child: Text('${index + 1}', style: Type.body(12.5, color: Colors.white, weight: FontWeight.w800))),
            ),
            if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: Tokens.sandDeep)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (travel > 0 && index > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 2),
                    child: Row(children: [const Icon(Icons.directions_walk_rounded, size: 14, color: Tokens.inkMuted), const SizedBox(width: 4), Text('~$travel min travel', style: Type.body(11.5, color: Tokens.inkMuted))]),
                  ),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Tokens.paper, borderRadius: BorderRadius.circular(20), border: Border.all(color: Tokens.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (item['image'] != null) SizedBox(height: 110, width: double.infinity, child: WImage(item['image'] as String?, width: double.infinity, height: 110)),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(categoryIcon(item['category'] as String?), size: 16, color: Tokens.jade),
                          const SizedBox(width: 6),
                          Expanded(child: Text(item['name'] as String, style: Type.body(15, weight: FontWeight.w800, height: 1.25))),
                          Text(cost == 0 ? 'Free' : money(cost), style: Type.body(13, weight: FontWeight.w800, color: Tokens.forest)),
                        ]),
                        if ((item['reason'] as String?)?.isNotEmpty ?? false) Padding(padding: const EdgeInsets.only(top: 6), child: Text(item['reason'] as String, style: Type.body(12.5, color: Tokens.inkMuted, height: 1.45))),
                        if (item['isDemo'] == true || item['is_demo'] == true) const Padding(padding: EdgeInsets.only(top: 8), child: DemoBadge()),
                        if (editing)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              IconButton(tooltip: 'Move up', visualDensity: VisualDensity.compact, onPressed: onUp, icon: const Icon(Icons.arrow_upward_rounded, size: 20)),
                              IconButton(tooltip: 'Move down', visualDensity: VisualDensity.compact, onPressed: onDown, icon: const Icon(Icons.arrow_downward_rounded, size: 20)),
                              IconButton(tooltip: 'Remove stop', visualDensity: VisualDensity.compact, onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Tokens.danger)),
                            ]),
                          ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Loaded itinerary (own or template): edit, reorder, remove, replace/regenerate, recalculate, copy.
class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  bool busy = false;

  Json _asPlan(Json it) {
    final days = (it['days'] as List).cast<Json>();
    return {
      'title': it['title'],
      'summary': it['summary'],
      'modeNote': it['generated_by'] == 'rules' || it['generated_by'] == 'curated' ? "Built by WAYFARER's deterministic rules engine from stored records, not an AI model." : null,
      'days': days,
      'assumptions': (it['assumptions'] as List?) ?? const [],
      'budget': {
        'lodgingUsd': 0, 'activitiesUsd': it['est_total_usd'], 'foodUsd': 0, 'transportUsd': 0, 'totalUsd': it['est_total_usd'], 'budgetUsd': it['budget_usd'],
        'withinBudget': it['budget_usd'] == null ? null : (it['est_total_usd'] as num) <= (it['budget_usd'] as num),
      },
      'destination': {'lat': it['dest_lat'], 'lng': it['dest_lng']},
    };
  }

  Future<void> _patchDay(Json it, int day, List<String> ids) async {
    setState(() => busy = true);
    try {
      await ref.read(apiProvider).patchJson('/itineraries/${widget.id}', body: {'days': [{'day': day, 'items': [for (final id in ids) {'attractionId': id}]}]});
      ref.invalidate(itineraryProvider(widget.id));
      ref.invalidate(itinerariesProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(itineraryProvider(widget.id));
    final me = ref.watch(authProvider).user;
    final money = ref.watch(moneyProvider);
    return Scaffold(
      body: res.when(
        loading: () => const SafeArea(child: Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 3, itemHeight: 150))),
        error: (e, _) => SafeArea(child: ErrorState(error: e, onRetry: () => ref.invalidate(itineraryProvider(widget.id)))),
        data: (it) {
          final mine = me != null && it['user_id'] == me['id'];
          final days = (it['days'] as List).cast<Json>();
          List<String> idsOf(int day) => (days[day - 1]['items'] as List).map((i) => (i as Json)['attractionId'] as String).toList();
          final cover = days.expand((d) => (d['items'] as List).cast<Json>()).map((i) => i['image']).whereType<String>().firstOrNull;
          return ToneOnScroll(child: ListView(padding: EdgeInsets.zero, children: [
            SizedBox(
              height: 250,
              child: Stack(fit: StackFit.expand, children: [
                Container(decoration: const BoxDecoration(gradient: Tokens.dusk)),
                if (cover != null) WImage(cover, full: true, width: double.infinity, height: double.infinity),
                const Scrim(top: true, strength: 0.9),
                Positioned(left: 12, top: MediaQuery.paddingOf(context).top + 8, child: GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onTap: () => context.canPop() ? context.pop() : context.go('/trips'))),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 22,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${it['destination_name']} · ${it['num_days']} DAYS'.toUpperCase(), style: Type.label(11, color: Tokens.gold)),
                    const SizedBox(height: 6),
                    Text(it['title'] as String, style: Type.display(28, color: Colors.white, height: 1.06), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 10, runSpacing: 10, children: [
                  if (!mine)
                    FilledButton.icon(
                      onPressed: busy ? null : () async {
                        if (me == null) {
                          context.push('/login?next=${Uri.encodeComponent('/trips/${widget.id}')}');
                          return;
                        }
                        try {
                          final c = await ref.read(apiProvider).postJson('/itineraries/${widget.id}/copy');
                          ref.invalidate(itinerariesProvider);
                          if (context.mounted) context.go('/trips/${c['id']}');
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        }
                      },
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('Copy to my trips'),
                    ),
                  if (mine) ...[
                    OutlinedButton.icon(
                      onPressed: busy ? null : () async {
                        setState(() => busy = true);
                        try {
                          final r = await ref.read(apiProvider).postJson('/itineraries/${widget.id}/recalculate');
                          ref.invalidate(itineraryProvider(widget.id));
                          if (context.mounted) showInfo(context, 'Estimate recalculated: ${money(r['totalUsd'] as num)}');
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        }
                        if (mounted) setState(() => busy = false);
                      },
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Recalculate'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Tokens.danger),
                      onPressed: () async {
                        final ok = await confirm(context, title: 'Delete this trip?', message: 'This removes the itinerary from your account.', confirmLabel: 'Delete', destructive: true);
                        if (!ok) return;
                        await ref.read(apiProvider).delete('/itineraries/${widget.id}');
                        ref.invalidate(itinerariesProvider);
                        if (context.mounted) context.go('/trips');
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                    ),
                  ],
                ]),
                const SizedBox(height: 18),
                PlanView(
                  plan: _asPlan(it),
                  editing: mine,
                  onRemove: (day, i) {
                    final ids = idsOf(day)..removeAt(i);
                    _patchDay(it, day, ids);
                  },
                  onMove: (day, from, to) {
                    final ids = idsOf(day);
                    final x = ids.removeAt(from);
                    ids.insert(to, x);
                    _patchDay(it, day, ids);
                  },
                  onRegenerate: (day) async {
                    setState(() => busy = true);
                    try {
                      await ref.read(apiProvider).postJson('/itineraries/${widget.id}/generate', body: {'day': day});
                      ref.invalidate(itineraryProvider(widget.id));
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                    if (mounted) setState(() => busy = false);
                  },
                ),
                if (mine)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _addStop(context, it, days), icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Add a stop'))),
                  ),
                const SizedBox(height: 56),
              ]),
            ),
          ]));
        },
      ),
    );
  }

  Future<void> _addStop(BuildContext context, Json it, List<Json> days) async {
    final slug = it['destination_slug'] as String;
    var day = 1;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => Consumer(builder: (c, ref, _) {
          final places = ref.watch(destinationPlacesProvider((slug: slug, kind: null)));
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            builder: (c, scroll) => Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(children: [
                  Expanded(child: Text('Add a stop', style: Type.display(24))),
                  DropdownButton<int>(value: day, underline: const SizedBox.shrink(), items: [for (final d in days) DropdownMenuItem(value: d['day'] as int, child: Text('Day ${d['day']}'))], onChanged: (v) => set(() => day = v!)),
                ]),
              ),
              Expanded(
                child: AsyncView<Json>(
                  value: places,
                  data: (p) {
                    final items = (p['items'] as List).cast<Json>();
                    final used = {for (final d in days) for (final i in (d['items'] as List)) (i as Json)['attractionId']};
                    return ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: items.length,
                      itemBuilder: (c, i) {
                        final pl = items[i];
                        final inTrip = used.contains(pl['id']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PlaceTile(
                            pl,
                            trailing: inTrip
                                ? const Pill('In trip')
                                : IconButton(
                                    tooltip: 'Add to day $day',
                                    icon: const Icon(Icons.add_circle_rounded, color: Tokens.forest),
                                    onPressed: () {
                                      Navigator.pop(c);
                                      final ids = (days[day - 1]['items'] as List).map((x) => (x as Json)['attractionId'] as String).toList()..add(pl['id'] as String);
                                      _patchDay(it, day, ids);
                                    },
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}
