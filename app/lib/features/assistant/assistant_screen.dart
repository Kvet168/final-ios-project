import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

class _Msg {
  _Msg(
    this.fromUser,
    this.text, {
    this.sources = const [],
    this.cards = const [],
    this.followUps = const [],
    this.mode,
    this.grounded = true,
    this.disclaimer,
    this.intent,
    this.destination,
    this.failed = false,
    this.retry,
  });
  final bool fromUser;
  final String text;
  final List<Json> sources, cards;
  final List<String> followUps;
  final String? mode, disclaimer, intent;
  final Json? destination;
  final bool grounded, failed;
  final String? retry;
  bool revealed = false;
}

class _Starter {
  const _Starter(this.icon, this.title, this.question, this.color);
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String
  question; // stays English: the guide retrieval matches English guides
  final Color color;
}

String _tBestTime(AppLocalizations l) => l.starterBestTime;
String _tGettingAround(AppLocalizations l) => l.starterGettingAround;
String _tDailyBudget(AppLocalizations l) => l.starterDailyBudget;
String _tWhatToEat(AppLocalizations l) => l.starterWhatToEat;
String _tTempleEtiquette(AppLocalizations l) => l.starterTempleEtiquette;
String _tCancellation(AppLocalizations l) => l.starterCancellation;

const _starters = [
  _Starter(
    Icons.wb_sunny_rounded,
    _tBestTime,
    'What is the best time to visit Siem Reap?',
    Tokens.primary,
  ),
  _Starter(
    Icons.tram_rounded,
    _tGettingAround,
    'How do I get around Phnom Penh?',
    Tokens.primary,
  ),
  _Starter(
    Icons.payments_rounded,
    _tDailyBudget,
    'How much does a day in Phnom Penh cost?',
    Tokens.primary,
  ),
  _Starter(
    Icons.ramen_dining_rounded,
    _tWhatToEat,
    'What should I eat in Kampot?',
    Tokens.primary,
  ),
  _Starter(
    Icons.checkroom_rounded,
    _tTempleEtiquette,
    'What should I wear when visiting temples?',
    Tokens.primary,
  ),
  _Starter(
    Icons.event_available_rounded,
    _tCancellation,
    'How does free cancellation work?',
    Tokens.primary,
  ),
];

/// Travel guide chat. Answers are composed server-side from stored destination data and approved guides, with sources.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.initialQuestion, this.destination});
  final String? initialQuestion, destination;
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  static final Map<String, Json> _answers = {};
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final List<_Msg> msgs = [];
  bool busy = false;
  String? _topic;

  @override
  void initState() {
    super.initState();
    _topic = widget.destination;
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ask(widget.initialQuestion!),
      );
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final to = _scroll.position.maxScrollExtent;
      animate
          ? _scroll.animateTo(
              to,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            )
          : _scroll.jumpTo(to);
    });
  }

  Future<void> _ask(String q) async {
    q = q.trim();
    // Any non-empty message is sent: short ones like "Hi" or "ok" get a small-talk reply from the server.
    if (q.isEmpty || busy) return;
    tick();
    setState(() {
      msgs.add(_Msg(true, q));
      busy = true;
      _input.clear();
    });
    _toBottom();
    try {
      // The recent conversation goes with every question so follow-ups ("only Phnom Penh", "what about food?") keep their context.
      final history = [
        for (final m
            in msgs
                .where((m) => !m.failed && m.text.trim().isNotEmpty)
                .toList()
                .reversed
                .skip(1)
                .take(8)
                .toList()
                .reversed)
          {
            'role': m.fromUser ? 'user' : 'assistant',
            'text': m.text.length > 1400 ? m.text.substring(0, 1400) : m.text,
          },
      ];
      // A first question (including the starter cards) is answered instantly from this session's cache; follow-ups depend on the chat, so they are not cached.
      final key = '${_topic ?? ''}|${q.toLowerCase()}';
      final r =
          (history.isEmpty ? _answers[key] : null) ??
          await ref
              .read(apiProvider)
              .postJson(
                '/ai/assistant',
                body: {
                  'question': q,
                  if (_topic != null) 'destination': _topic,
                  if (history.isNotEmpty) 'history': history,
                },
                timeout: const Duration(seconds: 30),
              );
      if (history.isEmpty) _answers[key] = r;
      final dest = r['destination'] as Json?;
      if (dest != null) _topic = dest['slug'] as String?;
      msgs.add(
        _Msg(
          false,
          _AssistantBubbleState.tidy(r['answer'] as String),
          sources: ((r['sources'] as List?) ?? const []).cast<Json>(),
          cards: ((r['cards'] as List?) ?? const []).cast<Json>(),
          followUps: ((r['followUps'] as List?) ?? const []).cast<String>(),
          mode: r['mode'] as String?,
          grounded: r['grounded'] == true,
          disclaimer: r['disclaimer'] as String?,
          intent: r['intent'] as String?,
          destination: dest,
        ),
      );
    } catch (e) {
      msgs.add(
        _Msg(
          false,
          e is ApiException
              ? e.message
              : (mounted ? context.l10n.somethingWentWrong : ''),
          grounded: false,
          failed: true,
          retry: q,
        ),
      );
    }
    if (!mounted) return;
    setState(() => busy = false);
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(aiStatusProvider).value;
    final llm = status?['assistantMode'] == 'llm';
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return StatusTone.light(
      child: Scaffold(
        backgroundColor: Tokens.pageBg,
        body: Column(
          children: [
            _Header(
              llm: llm,
              onClear: msgs.isEmpty
                  ? null
                  : () => setState(() {
                      msgs.clear();
                      _topic = widget.destination;
                    }),
            ),
            Expanded(
              child: msgs.isEmpty
                  ? _Empty(onAsk: _ask, topic: _topic)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      itemCount: msgs.length + (busy ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == msgs.length) return const _Typing();
                        final m = msgs[i];
                        final latest = i == msgs.length - 1;
                        return m.fromUser
                            ? _UserBubble(m.text)
                            : _AssistantBubble(
                                key: ObjectKey(m),
                                m: m,
                                animate: latest && !m.revealed,
                                onTick: _toBottom,
                                onAsk: _ask,
                                showFollowUps: latest && !busy,
                              );
                      },
                    ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.only(
                bottom: kb > 0 ? 0 : MediaQuery.paddingOf(context).bottom,
              ),
              child: _Composer(
                controller: _input,
                focus: _focus,
                busy: busy,
                onSend: () => _ask(_input.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.llm, required this.onClear});
  final bool llm;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      8,
      MediaQuery.paddingOf(context).top + 6,
      8,
      14,
    ),
    decoration: const BoxDecoration(
      gradient: Tokens.dusk,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Close',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: Tokens.sunrise,
            boxShadow: [
              BoxShadow(
                color: Tokens.accent.withValues(alpha: .5),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Tokens.onAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.guideName,
                style: Type.display(20, color: Colors.white),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6EE7A8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    llm
                        ? context.l10n.guideModeLlm
                        : context.l10n.guideModeRules,
                    style: Type.body(12, color: Tokens.onDarkMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onClear != null)
          IconButton(
            tooltip: context.l10n.newChat,
            onPressed: onClear,
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
          ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAsk, required this.topic});
  final ValueChanged<String> onAsk;
  final String? topic;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
    children: [
      Reveal(
        child: Text(
          context.l10n.askMeAnything,
          style: Type.display(34, height: 1.05),
        ),
      ),
      const SizedBox(height: 10),
      Reveal(
        delay: const Duration(milliseconds: 80),
        child: Text(
          context.l10n.askIntro,
          style: Type.body(14.5, color: Tokens.inkMuted, height: 1.5),
        ),
      ),
      const SizedBox(height: 24),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Khmer lines are taller, so the cards get more height there.
        childAspectRatio: context.isKhmer ? 1.12 : 1.35,
        children: [
          for (final (i, s) in _starters.indexed)
            Reveal(
              delay: Duration(milliseconds: 120 + 60 * i),
              child: Pressable(
                onTap: () => onAsk(s.question),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Tokens.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Tokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(s.icon, size: 21, color: s.color),
                      ),
                      const Spacer(),
                      Text(
                        s.title(context.l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Type.body(14.5, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Type.body(
                          11.5,
                          color: Tokens.inkMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Reveal(
      dy: 10,
      duration: const Duration(milliseconds: 260),
      child: Container(
        margin: const EdgeInsets.only(top: 14, left: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: Tokens.dusk,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: Type.body(15, color: Colors.white, height: 1.4),
        ),
      ),
    ),
  );
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        border: Border.all(color: Tokens.border),
      ),
      child: const TypingDots(),
    ),
  );
}

class _AssistantBubble extends StatefulWidget {
  const _AssistantBubble({
    super.key,
    required this.m,
    required this.animate,
    required this.onTick,
    required this.onAsk,
    required this.showFollowUps,
  });
  final _Msg m;
  final bool animate, showFollowUps;
  final VoidCallback onTick;
  final ValueChanged<String> onAsk;

  @override
  State<_AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends State<_AssistantBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _showSources = false;

  @override
  void initState() {
    super.initState();
    final len = widget.m.text.length;
    // Fast reveal: the answer is already here, this only gives it a natural arrival. Capped at ~1.1s.
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (len * 7).clamp(250, 1100)),
    );
    if (widget.animate && !widget.m.failed) {
      _c.addListener(widget.onTick);
      _c.forward().whenComplete(() => widget.m.revealed = true);
    } else {
      _c.value = 1;
      widget.m.revealed = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Model answers use light Markdown: list markers become bullets and heading marks go; **bold** is styled in [_spans].
  static String tidy(String s) => s
      .replaceAllMapped(
        RegExp(r'^(\s*)[*\-]\s+', multiLine: true),
        (m) => '${m[1]}• ',
      )
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

  List<InlineSpan> _spans(String text, int shown) {
    final t = text.substring(0, shown.clamp(0, text.length));
    final out = <InlineSpan>[];
    // **bold** runs and citation badges like [1] or [1, 2].
    final re = RegExp(r'\*\*(.+?)\*\*|\[(\d+(?:\s*,\s*\d+)*)\]');
    var last = 0;
    // While the answer is still revealing, an opened ** without its closing pair is hidden rather than shown raw.
    String plain(String x) => x.replaceAll('**', '');
    for (final mt in re.allMatches(t)) {
      if (mt.start > last) {
        out.add(TextSpan(text: plain(t.substring(last, mt.start))));
      }
      last = mt.end;
      if (mt.group(1) != null) {
        out.add(
          TextSpan(
            text: mt.group(1),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
        continue;
      }
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Tokens.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mt.group(2)!.replaceAll(RegExp(r'\s'), ''),
              style: Type.body(
                11,
                weight: FontWeight.w800,
                color: Tokens.primaryText,
              ),
            ),
          ),
        ),
      );
    }
    if (last < t.length) out.add(TextSpan(text: plain(t.substring(last))));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final done = _c.value >= 1;
        final shown = (m.text.length * Curves.easeOut.transform(_c.value))
            .round();
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 14, right: 20),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: m.failed
                  ? Tokens.warning.withValues(alpha: .08)
                  : Tokens.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              border: Border.all(
                color: m.failed
                    ? Tokens.warning.withValues(alpha: .4)
                    : Tokens.border,
              ),
              boxShadow: Tokens.softShadow(0.04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _c.value = 1,
                  child: Text.rich(
                    TextSpan(
                      style: Type.body(15, height: 1.6, color: Tokens.ink),
                      children: _spans(m.text, done ? m.text.length : shown),
                    ),
                  ),
                ),
                if (done) ...[
                  if (m.failed && m.retry != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onAsk(m.retry!),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.l10n.tryAgain),
                      ),
                    ),
                  if (!m.grounded && !m.failed)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: m.mode == 'llm'
                          ? Pill(
                              context.l10n.generalKnowledge,
                              color: Tokens.inkMuted,
                              icon: Icons.public_rounded,
                            )
                          : Pill(
                              context.l10n.notInGuides,
                              color: Tokens.warning,
                              icon: Icons.help_outline_rounded,
                            ),
                    ),
                  if (m.cards.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: m.cards.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _CardTile(c: m.cards[i]),
                      ),
                    ),
                  ],
                  if (m.intent == 'plan' && m.destination != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/trips/new?destination=${m.destination!['slug']}',
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          context.l10n.planWithPlanner(
                            '${m.destination!['name']}',
                          ),
                        ),
                      ),
                    ),
                  if (m.sources.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Pressable(
                      onTap: () => setState(() => _showSources = !_showSources),
                      radius: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 15,
                            color: Tokens.inkMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.sourcesCount(m.sources.length),
                            style: Type.body(
                              12.5,
                              weight: FontWeight.w700,
                              color: Tokens.inkMuted,
                            ),
                          ),
                          Icon(
                            _showSources
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: Tokens.inkMuted,
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      alignment: Alignment.topCenter,
                      child: !_showSources
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (i, s) in m.sources.indexed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '[${i + 1}] ${s['title']} · ${s['source']}${s['isDemo'] == true ? context.l10n.demoContentSuffix : ''}',
                                      style: Type.body(
                                        12,
                                        color: Tokens.inkMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                if (m.disclaimer != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      m.disclaimer!,
                                      style: Type.body(
                                        11,
                                        color: Tokens.inkMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                  if (widget.showFollowUps && m.followUps.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in m.followUps.take(3))
                          _Suggest(f, widget.onAsk),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Suggest extends StatelessWidget {
  const _Suggest(this.text, this.onAsk);
  final String text;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => onAsk(text),
    radius: 99,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Tokens.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Tokens.primary.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.north_east_rounded, size: 14, color: Tokens.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
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
  );
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.c});
  final Json c;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => context.push(c['route'] as String),
    child: Container(
      width: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: Tokens.softShadow(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            WImage(
              c['image'] as String?,
              width: double.infinity,
              height: double.infinity,
              fallbackIcon: c['type'] == 'stay'
                  ? Icons.bed_outlined
                  : Icons.place_outlined,
            ),
            const Scrim(top: true, strength: 0.88),
            Positioned(
              left: 12,
              top: 10,
              child: Pill(
                switch (c['type']) {
                  'stay' => context.l10n.cardStay,
                  'place' => context.l10n.cardPlace,
                  _ => context.l10n.cardDestination,
                },
                color: Tokens.accent,
                solid: true,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Type.display(16, color: Colors.white, height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c['subtitle'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Type.body(12, color: Tokens.onDarkMuted),
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

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focus,
    required this.busy,
    required this.onSend,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: const BoxDecoration(color: Tokens.pageBg),
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 6, 4),
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Tokens.border),
        boxShadow: Tokens.softShadow(0.08),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              style: Type.body(15.5),
              decoration: InputDecoration(
                hintText: context.l10n.askHint,
                hintStyle: Type.body(15.5, color: Tokens.inkMuted),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // The button is greyed out while the box is empty, so it never looks broken.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final ready = !busy && value.text.trim().isNotEmpty;
              return Pressable(
                onTap: ready ? onSend : null,
                radius: 99,
                semanticLabel: context.l10n.send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ready ? Tokens.sunrise : null,
                    color: ready ? null : Tokens.border,
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Tokens.primary,
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          color: ready ? Tokens.onAccent : Tokens.inkMuted,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
