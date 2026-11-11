part of 'trips_screen.dart';

/// Itinerary → PDF that looks like the app.
///
/// Each block (cover with summary and budget, a header per day, one card per stop) is the same Flutter widget the
/// screen uses, painted off-screen and placed on A4 pages as an image. Painting through Flutter keeps the app's look
/// and shapes Khmer correctly, which PDF text layout cannot do. Days start on a new page; stops flow across pages.
/// The finished file opens the system share sheet (Save to Files, AirDrop, Mail, Print).
Future<void> exportPlanPdf(
  BuildContext context,
  WidgetRef ref,
  Json plan,
) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l.preparingPdf),
        duration: const Duration(seconds: 20),
      ),
    );
  try {
    final money = ref.read(moneyProvider);
    final days = (plan['days'] as List).cast<Json>();
    final cityCount = planCityNames(plan).length;

    await _precachePhotos(context, days);
    if (!context.mounted) return;

    // Blocks in reading order; null marks "start the next block on a new page".
    final blocks = <Widget?>[
      _PdfCover(plan: plan, money: money),
      for (final day in days) ...[
        null,
        _PdfDayHeader(day: day, money: money, showCity: cityCount > 1),
        if (day['transfer'] != null)
          _TransferCard(transfer: day['transfer'] as Json, money: money),
        for (final (i, it) in (day['items'] as List).cast<Json>().indexed)
          _Stop(
            index: i,
            item: it,
            last: i == (day['items'] as List).length - 1,
            money: money,
            editing: false,
            animate: false,
          ),
      ],
    ];
    final images = await _paintOffscreen(
      context,
      blocks.whereType<Widget>().toList(),
    );
    if (!context.mounted) return;

    final bytes = await _buildPdf(blocks, images);
    messenger.hideCurrentSnackBar();
    final slug = ((plan['title'] as String?) ?? 'itinerary')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'wayfarer-${slug.isEmpty ? 'itinerary' : slug}.pdf',
    );
  } catch (e) {
    debugPrint('PDF export failed: $e');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.pdfFailed), backgroundColor: Tokens.danger),
      );
  }
}

/// Logical width the blocks are laid out at (about a phone held in landscape); scaled to the A4 text width.
const double _pdfBlockWidth = 600;
const double _pdfPixelRatio = 2.4;

/// Loads every stop photo at the size the cards decode it, so the off-screen paint shows photos, not placeholders.
Future<void> _precachePhotos(BuildContext context, List<Json> days) async {
  final futures = <Future<void>>[];
  for (final day in days) {
    for (final it in (day['items'] as List).cast<Json>()) {
      final url = it['image'] as String?;
      if (url == null || url.isEmpty) continue;
      final asset = ImageCatalog.assetFor(url);
      final ImageProvider base = asset != null
          ? AssetImage(asset)
          : NetworkImage(
              url.contains('/img/') && !url.contains('/img/t/')
                  ? url.replaceFirst('/img/', '/img/t/')
                  : url,
            );
      // Same key as WImage (cacheWidth 640), so the card finds the decoded image synchronously.
      futures.add(
        precacheImage(
          ResizeImage.resizeIfNeeded(640, null, base),
          context,
          onError: (_, _) {},
        ),
      );
    }
  }
  await Future.wait(futures)
      .timeout(const Duration(seconds: 15), onTimeout: () => const []);
}

/// A4 with the margins and footer used below.
const _pdfFormat = PdfPageFormat.a4;
const double _pdfMargin = 34;
const double _pdfFooter = 26;

/// Tallest slice (in logical pixels at [_pdfBlockWidth]) that still fits on one page.
double get _maxSliceLogical {
  final contentWidth = _pdfFormat.width - _pdfMargin * 2;
  final contentHeight = _pdfFormat.height - _pdfMargin * 2 - _pdfFooter;
  return contentHeight * _pdfBlockWidth / contentWidth - 4;
}

/// Paints [blocks] in an overlay entry placed off-screen. Each block becomes one PNG, or several stacked slices when it
/// is taller than a page (a long summary, many assumptions), since PDF images cannot break across pages.
Future<List<List<Uint8List>>> _paintOffscreen(
  BuildContext context,
  List<Widget> blocks,
) async {
  final keys = [for (final _ in blocks) GlobalKey()];
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -_pdfBlockWidth * 4,
      top: 0,
      width: _pdfBlockWidth,
      // The overlay gives an entry with only `top` set an unbounded height, so the column takes its natural height.
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: true, textScaler: TextScaler.noScaling),
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, b) in blocks.indexed)
                RepaintBoundary(
                  key: keys[i],
                  child: ColoredBox(color: Colors.white, child: b),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  try {
    // Two frames: one to lay out, one for images that resolve from cache during the first.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await WidgetsBinding.instance.endOfFrame;
    final out = <List<Uint8List>>[];
    final sliceH = (_maxSliceLogical * _pdfPixelRatio).floor();
    for (final k in keys) {
      final boundary =
          k.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _pdfPixelRatio);
      final slices = <Uint8List>[];
      for (var y = 0; y < image.height; y += sliceH) {
        final h = (image.height - y).clamp(1, sliceH);
        final ui.Image part;
        if (y == 0 && h == image.height) {
          part = image;
        } else {
          final rec = ui.PictureRecorder();
          Canvas(rec).drawImageRect(
            image,
            Rect.fromLTWH(
              0,
              y.toDouble(),
              image.width.toDouble(),
              h.toDouble(),
            ),
            Rect.fromLTWH(0, 0, image.width.toDouble(), h.toDouble()),
            Paint(),
          );
          part = await rec.endRecording().toImage(image.width, h);
        }
        final data = await part.toByteData(format: ui.ImageByteFormat.png);
        if (!identical(part, image)) part.dispose();
        slices.add(data!.buffer.asUint8List());
      }
      image.dispose();
      out.add(slices);
    }
    return out;
  } finally {
    entry.remove();
  }
}

// PNG size from the IHDR chunk (big-endian width and height at bytes 16 and 20).
int _pngWidth(Uint8List png) => ByteData.sublistView(png, 16, 20).getUint32(0);
int _pngHeight(Uint8List png) => ByteData.sublistView(png, 20, 24).getUint32(0);

Future<Uint8List> _buildPdf(
  List<Widget?> blocks,
  List<List<Uint8List>> images,
) async {
  final doc = pw.Document(
    title: 'WAYFARER itinerary',
    author: 'WAYFARER',
    creator: 'WAYFARER',
  );
  const format = _pdfFormat;
  const margin = _pdfMargin;
  final width = format.width - margin * 2;

  // Split into pages at the null markers: the cover, then one section per day.
  final sections = <List<Uint8List>>[[]];
  var n = 0;
  for (final b in blocks) {
    if (b == null) {
      sections.add([]);
    } else {
      sections.last.addAll(images[n++]);
    }
  }

  for (final section in sections.where((s) => s.isNotEmpty)) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.fromLTRB(margin, margin, margin, margin),
        footer: (ctx) => pw.Container(
          height: _pdfFooter,
          alignment: pw.Alignment.bottomCenter,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'WAYFARER',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFFC7364B),
                  letterSpacing: 2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        // Explicit height: MultiPage measures an image at its pixel size unless both dimensions are given.
        build: (_) => [
          for (final png in section)
            pw.Image(
              pw.MemoryImage(png),
              width: width,
              height: width * _pngHeight(png) / _pngWidth(png),
              fit: pw.BoxFit.fill,
            ),
        ],
      ),
    );
  }
  return doc.save();
}

/// First page: brand band, title, summary, how it was made, and the budget split.
class _PdfCover extends StatelessWidget {
  const _PdfCover({required this.plan, required this.money});
  final Json plan;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final days = (plan['days'] as List).cast<Json>();
    final budget = plan['budget'] as Json?;
    final cities = planCityNames(plan);
    final assumptions = ((plan['assumptions'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final warnings = ((plan['warnings'] as List?) ?? const []).cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
          decoration: BoxDecoration(
            gradient: Tokens.dusk,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.pdfBrandLine,
                style: Type.label(10.5, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                (plan['title'] as String?) ?? l.planTrip,
                style: Type.display(30, color: Colors.white, height: 1.08),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cities) _whitePill(Icons.place_outlined, c),
                  _whitePill(
                    Icons.calendar_today_outlined,
                    l.daysCount(days.length),
                  ),
                  _whitePill(
                    Icons.event_note_outlined,
                    l.pdfCreatedOn(
                      fmtDate(
                        DateTime.now().toIso8601String(),
                        pattern: 'd MMM y',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (plan['summary'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              plan['summary'] as String,
              style: Type.body(13.5, color: Tokens.inkSoft, height: 1.55),
            ),
          ),
        if (plan['modeNote'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  plan['mode'] == 'llm'
                      ? Icons.auto_awesome_rounded
                      : Icons.rule_rounded,
                  size: 14,
                  color: Tokens.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plan['modeNote'] as String,
                    style: Type.body(
                      11,
                      color: Tokens.primaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (final w in warnings)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Tokens.promo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(w, style: Type.body(12, height: 1.45)),
            ),
          ),
        if (budget != null) ...[
          const SizedBox(height: 18),
          _PdfBudget(plan: plan, budget: budget, money: money),
        ],
        if (assumptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l.assumptions,
            style: Type.body(
              12.5,
              weight: FontWeight.w800,
              color: Tokens.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          for (final a in assumptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $a',
                style: Type.body(11.5, color: Tokens.inkMuted, height: 1.45),
              ),
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  static Widget _whitePill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          text,
          style: Type.body(11.5, color: Colors.white, weight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// The budget card without animation or the collapsible assumptions (those are listed in full on the cover).
class _PdfBudget extends StatelessWidget {
  const _PdfBudget({
    required this.plan,
    required this.budget,
    required this.money,
  });
  final Json plan, budget;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parts = [
      (l.budgetStay, (budget['lodgingUsd'] as num).toDouble(), Tokens.primary),
      (
        l.budgetActivities,
        (budget['activitiesUsd'] as num).toDouble(),
        Tokens.inkSoft,
      ),
      (l.budgetFood, (budget['foodUsd'] as num).toDouble(), Tokens.star),
      (
        l.budgetTransport,
        (budget['transportUsd'] as num).toDouble(),
        Tokens.sky,
      ),
    ].where((p) => p.$2 > 0).toList();
    final total = (budget['totalUsd'] as num).toDouble();
    final within = budget['withinBudget'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.estimatedTotalCaps, style: Type.label(10)),
          const SizedBox(height: 4),
          Text(money(total), style: Type.display(34, height: 1.05)),
          if (budget['budgetUsd'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    within == true
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: within == true ? Tokens.success : Tokens.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    within == true
                        ? l.withinBudget(money(budget['budgetUsd'] as num))
                        : l.overBudget(money(budget['budgetUsd'] as num)),
                    style: Type.body(
                      12.5,
                      weight: FontWeight.w800,
                      color: within == true ? Tokens.success : Tokens.danger,
                    ),
                  ),
                ],
              ),
            ),
          if (total > 0 && parts.length > 1) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final p in parts)
                      Expanded(
                        flex: (p.$2 / total * 1000).round().clamp(1, 1000),
                        child: Container(color: p.$3),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final p in parts)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: p.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${p.$1} ',
                        style: Type.body(12, color: Tokens.inkMuted),
                      ),
                      Text(
                        money(p.$2),
                        style: Type.body(12, weight: FontWeight.w800),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (plan['lodging'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.bed_outlined, size: 16, color: Tokens.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.lodgingNights(
                      '${plan['lodging']['name']}',
                      plan['lodging']['nights'] as int,
                    ),
                    style: Type.body(12.5, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Day 1" pill with the day's stop count and cost, as in the day picker on screen.
class _PdfDayHeader extends StatelessWidget {
  const _PdfDayHeader({
    required this.day,
    required this.money,
    this.showCity = false,
  });
  final Json day;
  final String Function(num) money;
  final bool showCity;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = (day['items'] as List);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: Tokens.primaryText,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              showCity && (day['destination'] as Map?)?['name'] != null
                  ? l.dayInCity(
                      day['day'] as int,
                      (day['destination'] as Map)['name'] as String,
                    )
                  : l.pdfDayTitle(day['day'] as int),
              style: Type.body(
                14,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${l.stopsCount(items.length)} · ${money(day['costUsd'] as num? ?? 0)}',
              style: Type.body(
                13,
                weight: FontWeight.w700,
                color: Tokens.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
