import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';

/// Opens the stay search as a bottom sheet. [onSearch] receives the query; without it the app navigates to the Stays tab.
Future<void> showSearchSheet(
  BuildContext context, {
  StayQuery initial = const StayQuery(),
  void Function(StayQuery)? onSearch,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true, // cover the bottom bar instead of sliding under it
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(c).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.findYourStay, style: Type.display(28)),
            const SizedBox(height: 4),
            Text(
              context.l10n.realAvailability,
              style: Type.body(14, color: Tokens.inkMuted),
            ),
            const SizedBox(height: 20),
            SearchPanel(
              initial: initial,
              embedded: true,
              onSearch: (q) {
                Navigator.of(c).pop();
                if (onSearch != null) {
                  onSearch(q);
                } else {
                  context.go(
                    Uri(
                      path: '/stays',
                      queryParameters: q.toUrlParams(),
                    ).toString(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Destination + dates + guests search.
class SearchPanel extends ConsumerStatefulWidget {
  const SearchPanel({
    super.key,
    this.initial = const StayQuery(),
    this.onSearch,
    this.embedded = false,
  });
  final StayQuery initial;
  final void Function(StayQuery)? onSearch;
  final bool embedded;

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  late StayQuery q = widget.initial;
  late final TextEditingController _dest = TextEditingController();
  final FocusNode _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _dest.text = q.q ?? q.destination?.replaceAll('-', ' ') ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFromSlug(
          (ref.read(metaProvider).value?['destinations'] as List?) ?? const [],
        );
      }
    });
  }

  /// Show the human name ("Phnom Penh") instead of the URL slug once the destination list is available.
  void _nameFromSlug(List dests) {
    if (q.destination == null ||
        _dest.text != q.destination!.replaceAll('-', ' ')) {
      return;
    }
    final m = dests
        .cast<Map>()
        .where((d) => d['slug'] == q.destination)
        .firstOrNull;
    if (m != null) _dest.text = m['name'] as String;
  }

  @override
  void dispose() {
    _dest.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 119)),
      initialDateRange: q.hasDates
          ? DateTimeRange(
              start: DateTime.parse(q.checkIn!),
              end: DateTime.parse(q.checkOut!),
            )
          : null,
      helpText: context.l10n.selectCheckInOut,
      saveText: context.l10n.done,
    );
    if (r != null) {
      setState(
        () => q = q.copyWith(checkIn: iso(r.start), checkOut: iso(r.end)),
      );
    }
  }

  Future<void> _pickGuests() async {
    var adults = q.adults, children = q.children, rooms = q.rooms;
    await showModalBottomSheet<void>(
      useRootNavigator:
          true, // cover the bottom bar instead of sliding under it
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          Widget row(
            String label,
            String sub,
            int v,
            int min,
            int max,
            void Function(int) on,
          ) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Type.body(16, weight: FontWeight.w700),
                      ),
                      if (sub.isNotEmpty)
                        Text(sub, style: Type.body(13, color: Tokens.inkMuted)),
                    ],
                  ),
                ),
                _Stepper(
                  onTap: v > min ? () => set(() => on(v - 1)) : null,
                  icon: Icons.remove_rounded,
                  label: context.l10n.fewer(label),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$v',
                    textAlign: TextAlign.center,
                    style: Type.display(22),
                  ),
                ),
                _Stepper(
                  onTap: v < max ? () => set(() => on(v + 1)) : null,
                  icon: Icons.add_rounded,
                  label: context.l10n.more(label),
                ),
              ],
            ),
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row(
                    context.l10n.adults,
                    context.l10n.adultsAge,
                    adults,
                    1,
                    12,
                    (v) => adults = v,
                  ),
                  row(
                    context.l10n.children,
                    context.l10n.childrenAge,
                    children,
                    0,
                    8,
                    (v) => children = v,
                  ),
                  row(context.l10n.rooms, '', rooms, 1, 6, (v) => rooms = v),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(context.l10n.apply),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    setState(
      () => q = q.copyWith(adults: adults, children: children, rooms: rooms),
    );
  }

  void _submit(List destinations) {
    final text = _dest.text.trim();
    String? slug;
    String? free;
    if (text.isNotEmpty) {
      final match = destinations
          .cast<Map>()
          .where(
            (d) =>
                (d['name'] as String).toLowerCase() == text.toLowerCase() ||
                d['slug'] == text.toLowerCase(),
          )
          .firstOrNull;
      if (match != null) {
        slug = match['slug'] as String;
      } else {
        free = text;
      }
    }
    if (q.hasDates && q.checkIn!.compareTo(q.checkOut!) >= 0) {
      setState(() => _error = context.l10n.checkoutAfterCheckin);
      return;
    }
    setState(() => _error = null);
    final next = q.copyWith(destination: slug, q: free, page: 1);
    if (widget.onSearch != null) {
      widget.onSearch!(next);
    } else {
      context.go(
        Uri(path: '/stays', queryParameters: next.toUrlParams()).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dests =
        (ref.watch(metaProvider).value?['destinations'] as List?) ?? const [];
    ref.listen(
      metaProvider,
      (_, next) =>
          _nameFromSlug((next.value?['destinations'] as List?) ?? const []),
    );
    final dateLabel = q.hasDates
        ? '${fmtDate(q.checkIn, pattern: 'd MMM')} – ${fmtDate(q.checkOut, pattern: 'd MMM')}  ·  ${context.l10n.nightsCount(nightsBetween(q.checkIn, q.checkOut))}'
        : context.l10n.addDates;
    final guestLabel =
        '${context.l10n.adultsCount(q.adults)}${q.children > 0 ? ', ${context.l10n.childrenCount(q.children)}' : ''} · ${context.l10n.roomsCount(q.rooms)}';

    final destField = RawAutocomplete<String>(
      textEditingController: _dest,
      focusNode: _focus,
      optionsBuilder: (v) {
        final t = v.text.trim().toLowerCase();
        return dests
            .cast<Map>()
            .map((d) => d['name'] as String)
            .where((n) => t.isEmpty || n.toLowerCase().contains(t))
            .take(8);
      },
      onSelected: (v) => _dest.text = v,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submit(dests),
        decoration: InputDecoration(
          labelText: context.l10n.whereTo,
          hintText: context.l10n.whereToHint,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          color: Tokens.surface,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: Tokens.primary,
                    ),
                    title: Text(
                      o,
                      style: Type.body(15, weight: FontWeight.w600),
                    ),
                    onTap: () => onSelected(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    Widget tapField(
      IconData icon,
      String label,
      String value,
      VoidCallback onTap,
    ) => Semantics(
      button: true,
      label: context.l10n.fieldValue(label, value),
      child: Pressable(
        onTap: onTap,
        radius: 16,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Type.body(15, weight: FontWeight.w600),
          ),
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        destField,
        const SizedBox(height: 12),
        tapField(
          Icons.calendar_month_outlined,
          context.l10n.dates,
          dateLabel,
          _pickDates,
        ),
        const SizedBox(height: 12),
        tapField(
          Icons.people_outline,
          context.l10n.guests,
          guestLabel,
          _pickGuests,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _submit(dests),
          icon: const Icon(Icons.search_rounded),
          label: Text(context.l10n.searchStays),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 58)),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: Type.body(13, color: Tokens.danger)),
          ),
      ],
    );

    if (widget.embedded) return content;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(Tokens.radius),
        border: Border.all(color: Tokens.border),
      ),
      child: content,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.onTap,
    required this.icon,
    required this.label,
  });
  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    radius: 99,
    semanticLabel: label,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: onTap == null ? Tokens.border : Tokens.primary,
          width: 1.5,
        ),
      ),
      child: Icon(icon, color: onTap == null ? Tokens.border : Tokens.primary),
    ),
  );
}
