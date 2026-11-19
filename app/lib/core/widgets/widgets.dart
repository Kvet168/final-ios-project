import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

import '../data/providers.dart';
import '../network/api_client.dart';
import '../theme/theme.dart';
import 'image_catalog.dart';
import 'ui.dart';

export '../../l10n/l10n.dart';
export 'ui.dart';

/* ------------------------------------------------------------------ formatting */

final moneyProvider = Provider<String Function(num usd)>((ref) {
  final code = ref.watch(currencyProvider);
  final meta = ref.watch(metaProvider).value;
  final list = (meta?['currencies'] as List?) ?? const [];
  final row = list
      .cast<Map>()
      .where((c) => c['code'] == code)
      .cast<Map?>()
      .firstOrNull;
  final rate = (row?['per_usd'] as num?)?.toDouble() ?? 1.0;
  final symbol = (row?['symbol'] as String?) ?? r'$';
  final active = row != null ? code : 'USD';
  return (num usd) {
    final v = usd * (row != null ? rate : 1);
    final noDecimals =
        (rate >= 100 && active != 'USD') || v == v.roundToDouble();
    final f = NumberFormat.decimalPattern()
      ..minimumFractionDigits = noDecimals ? 0 : 2
      ..maximumFractionDigits = noDecimals ? 0 : 2;
    final prefix = active == 'USD' ? r'$' : symbol;
    return '$prefix${f.format(v)}';
  };
});

String fmtDate(String? iso, {String pattern = 'EEE d MMM'}) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat(pattern).format(d.toLocal());
}

/// Minutes after midnight as a clock time in the current language (9:30 AM / ៩:៣០ ព្រឹក).
String fmtMinutes(int m) => DateFormat.jm()
    .format(DateTime(2000, 1, 1, (m ~/ 60) % 24, m % 60))
    .replaceAll('\u202F', ' ');

String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

int nightsBetween(String? a, String? b) {
  if (a == null || b == null) return 0;
  final x = DateTime.tryParse(a), y = DateTime.tryParse(b);
  if (x == null || y == null) return 0;
  return y.difference(x).inDays;
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/* ------------------------------------------------------------------ layout */

/// Centres content and caps its width (keeps tablets and landscape tidy) with phone-friendly gutters.
class Constrained extends StatelessWidget {
  const Constrained({
    super.key,
    required this.child,
    this.maxWidth = Tokens.maxContent,
    this.padding,
  });
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      ),
    ),
  );
}

bool isWide(BuildContext c) => MediaQuery.sizeOf(c).width >= 840;

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.onAction,
  });
  final String title;
  final String? subtitle, action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SectionTitle(
    title,
    eyebrow: subtitle,
    action: action,
    onAction: onAction,
    padding: const EdgeInsets.only(top: 28, bottom: 12),
  );
}

/* ------------------------------------------------------------------ imagery */

/// Photo with a calm tonal fallback (never a broken-image icon). Bundled photos load instantly from the app;
/// anything else is fetched from the network with one retry. Decoded at a capped size to keep memory low.
class WImage extends StatefulWidget {
  const WImage(
    this.url, {
    super.key,
    this.height,
    this.width,
    this.radius = 0,
    this.fallbackIcon = Icons.landscape_outlined,
    this.label,
    this.full = false,
    this.alignment = Alignment.center,
  });
  final String? url;
  final double? height, width, radius;
  final IconData fallbackIcon;
  final String? label;
  final bool full;
  final Alignment alignment;

  @override
  State<WImage> createState() => _WImageState();
}

class _WImageState extends State<WImage> {
  int _attempt = 0;
  bool _retryScheduled = false;

  String? get _netSrc {
    var u = widget.url;
    if (u == null || u.isEmpty) return null;
    if (!widget.full && u.contains('/img/') && !u.contains('/img/t/')) {
      u = u.replaceFirst('/img/', '/img/t/');
    }
    return _attempt == 0 ? u : '$u?r=$_attempt';
  }

  Widget _fallback() => Container(
    height: widget.height,
    width: widget.width,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Tokens.neutralTint, Tokens.border],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        widget.fallbackIcon,
        color: Tokens.primary.withValues(alpha: 0.4),
        size: 34,
      ),
    ),
  );

  @override
  void didUpdateWidget(covariant WImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _attempt = 0;
      _retryScheduled = false;
    }
  }

  Widget _fade(BuildContext context, Widget child, int? frame, bool sync) {
    if (sync) return child;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Container(
          height: widget.height,
          width: widget.width,
          color: Tokens.neutralTint,
        ),
        AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = ImageCatalog.assetFor(widget.url, full: widget.full);
    final net = _netSrc;
    final cacheW = widget.full ? 1280 : 640;
    final Widget child;
    if (asset != null) {
      child = Image.asset(
        asset,
        height: widget.height,
        width: widget.width,
        fit: BoxFit.cover,
        alignment: widget.alignment,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        cacheWidth: cacheW,
        frameBuilder: (c, ch, frame, sync) => _fade(c, ch, frame, sync),
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else if (net == null) {
      child = _fallback();
    } else {
      child = Image.network(
        net,
        key: ValueKey(net),
        height: widget.height,
        width: widget.width,
        fit: BoxFit.cover,
        alignment: widget.alignment,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        cacheWidth: cacheW,
        frameBuilder: (c, ch, frame, sync) => _fade(c, ch, frame, sync),
        errorBuilder: (context, error, stack) {
          if (_attempt < 2 && !_retryScheduled) {
            _retryScheduled = true;
            Future<void>.delayed(const Duration(milliseconds: 900), () {
              if (mounted) {
                setState(() {
                  _attempt++;
                  _retryScheduled = false;
                });
              }
            });
          }
          return _fallback();
        },
      );
    }
    return Semantics(
      image: true,
      label: widget.label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius ?? 0),
        child: child,
      ),
    );
  }
}

/// Dark scrim for text laid over photography.
class Scrim extends StatelessWidget {
  const Scrim({
    super.key,
    this.top = false,
    this.bottom = true,
    this.strength = 0.72,
  });
  final bool top, bottom;
  final double strength;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              top ? Colors.black.withValues(alpha: 0.38) : Colors.transparent,
              Colors.transparent,
              if (bottom) Tokens.charcoal.withValues(alpha: 0.12),
              if (bottom) Tokens.charcoal.withValues(alpha: strength),
            ],
            stops: bottom ? const [0, 0.35, 0.55, 1] : const [0, 1, 1, 1],
          ),
        ),
      ),
    ),
  );
}

/* ------------------------------------------------------------------ states */

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });
  final double height;
  final double? width;
  final double radius;
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Tokens.tint,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 220});
  final int count;
  final double itemHeight;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loading,
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SkeletonBox(height: itemHeight, radius: Tokens.radius),
          ),
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final network = e is ApiException && e.isNetwork;
    final l = context.l10n;
    final msg = e is ApiException ? e.message : l.genericError;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Tokens.warning.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  network
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline_rounded,
                  size: 34,
                  color: Tokens.warning,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                network ? l.noConnection : l.didntLoad,
                style: Type.display(24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: Type.body(14.5, color: Tokens.inkMuted, height: 1.5),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.tryAgain),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.search_off_rounded,
    this.action,
  });
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Tokens.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Tokens.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: Type.display(23), textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Type.body(14.5, color: Tokens.inkMuted, height: 1.5),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    ),
  );
}

/// Standard async rendering: skeleton while loading, retryable error, data builder.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () =>
        loading ??
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SkeletonList(),
        ),
    error: (e, _) => ErrorState(error: e, onRetry: onRetry),
  );
}

/* ------------------------------------------------------------------ small pieces */

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = Tokens.primary,
    this.icon,
    this.solid = false,
  });
  final String text;
  final Color color;
  final IconData? icon;
  final bool solid;
  @override
  Widget build(BuildContext context) {
    // Coral text on tinted pills uses the deeper coral for contrast; solid coral pills use the deeper coral fill with white text.
    final isAccent = color == Tokens.accent;
    final fg = solid ? Colors.white : (isAccent ? Tokens.primaryText : color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid
            ? (isAccent ? Tokens.primaryText : color)
            : color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: Type.body(12, weight: FontWeight.w700, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    required this.count,
    this.light = false,
  });
  final num rating;
  final int count;
  final bool light;
  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        context.l10n.ratingNew,
        style: Type.body(
          12,
          color: light ? Tokens.onDarkMuted : Tokens.inkMuted,
          weight: FontWeight.w700,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 17, color: Tokens.star),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: Type.body(
            13.5,
            weight: FontWeight.w800,
            color: light ? Colors.white : Tokens.ink,
          ),
        ),
        Text(
          '  ($count)',
          style: Type.body(
            12,
            color: light ? Tokens.onDarkMuted : Tokens.inkMuted,
          ),
        ),
      ],
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow(this.stars, {super.key, this.size = 14});
  final int stars;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.starProperty(stars),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < stars; i++)
          Icon(Icons.star_rounded, size: size, color: Tokens.star),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (label, color, icon) = switch (status) {
      'CONFIRMED' => (
        l.statusConfirmed,
        Tokens.success,
        Icons.check_circle_outline,
      ),
      'PENDING_CONFIRMATION' => (
        l.statusAwaitingPayment,
        Tokens.warning,
        Icons.hourglass_bottom_rounded,
      ),
      'CHECKED_IN' => (l.statusCheckedIn, Tokens.primary, Icons.login_rounded),
      'COMPLETED' => (
        l.statusCompleted,
        Tokens.primary,
        Icons.task_alt_rounded,
      ),
      'CANCELLED' => (l.statusCancelled, Tokens.danger, Icons.cancel_outlined),
      'EXPIRED' => (l.statusExpired, Tokens.inkMuted, Icons.timer_off_outlined),
      'REFUND_PENDING' => (
        l.statusRefundPending,
        Tokens.warning,
        Icons.undo_rounded,
      ),
      'REFUNDED' => (l.statusRefunded, Tokens.inkMuted, Icons.undo_rounded),
      'DRAFT' => (l.statusDraft, Tokens.inkMuted, Icons.edit_outlined),
      'SUCCESS' => (l.statusPaid, Tokens.success, Icons.check_circle_outline),
      'FAILED' => (l.statusPaymentFailed, Tokens.danger, Icons.error_outline),
      'PENDING' => (
        l.statusPaymentPending,
        Tokens.warning,
        Icons.hourglass_bottom_rounded,
      ),
      _ => (status, Tokens.inkMuted, Icons.info_outline),
    };
    return Pill(label, color: color, icon: icon);
  }
}

class PriceRow extends StatelessWidget {
  const PriceRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.muted = false,
  });
  final String label, value;
  final bool bold, muted;
  @override
  Widget build(BuildContext context) {
    final style = Type.body(
      bold ? 16 : 14,
      weight: bold ? FontWeight.w800 : FontWeight.w500,
      color: muted ? Tokens.inkMuted : Tokens.ink,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

void showError(BuildContext context, Object e) {
  final msg = e is ApiException ? e.message : context.l10n.genericError;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Tokens.danger),
    );
}

void showInfo(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: Type.body(14.5, color: Tokens.inkSoft, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(context.l10n.keep),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Tokens.danger,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                )
              : FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel ?? context.l10n.confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}
