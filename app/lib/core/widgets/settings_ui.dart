import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../theme/theme.dart';

/// Small round back button used by every pushed screen.
class BackChip extends StatelessWidget {
  const BackChip({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: Tokens.surface,
      shape: const CircleBorder(side: BorderSide(color: Tokens.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.canPop() ? context.pop() : context.go('/account'),
        child: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: Tokens.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

/// A pushed screen: back button, left-aligned title, light grey page, content that scrolls.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.footer,
  });
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  /// Pinned under the scrolling content (primary action).
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Tokens.pageBg,
    appBar: AppBar(
      backgroundColor: Tokens.pageBg,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: const Padding(
        padding: EdgeInsets.only(left: 20),
        child: BackChip(),
      ),
      titleSpacing: 12,
      title: Text(title, style: Type.display(20)),
      actions: [...?actions, const SizedBox(width: 8)],
    ),
    body: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: children,
      ),
    ),
    bottomNavigationBar: footer == null
        ? null
        : AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: footer,
              ),
            ),
          ),
  );
}

/// Small heading above a settings group.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: Text(
      text,
      style: Type.body(14, weight: FontWeight.w600, color: Tokens.inkMuted),
    ),
  );
}

/// White rounded card holding rows separated by hairlines inset to the label.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Tokens.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            const Divider(height: 1, indent: 62, color: Tokens.neutralTint),
        ],
      ],
    ),
  );
}

/// One row: small rounded icon tile, label, optional value, muted chevron (or a switch).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.value,
    this.danger = false,
    this.chevron = true,
    this.toggle,
    this.onToggle,
  });
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool danger, chevron;
  final bool? toggle;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? Tokens.danger : Tokens.ink;
    return InkWell(
      onTap: toggle == null ? onTap : () => onToggle?.call(!toggle!),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: danger ? const Color(0xFFFBEAE6) : Tokens.pageBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: fg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Type.body(15.5, weight: FontWeight.w500, color: fg),
                ),
              ),
              if (value != null) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    value!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Type.body(14, color: Tokens.inkMuted),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (toggle != null)
                Switch(value: toggle!, onChanged: onToggle)
              else if (chevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Tokens.inkMuted.withValues(alpha: .6),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for list screens: left-aligned inside the content column, not floating mid-screen.
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Tokens.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Tokens.tint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: Tokens.primary),
        ),
        const SizedBox(height: 18),
        Text(title, style: Type.display(19, height: 1.2)),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            style: Type.body(14.5, color: Tokens.inkMuted, height: 1.5),
          ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
            child: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}

/// Round profile picture: the uploaded photo when there is one, otherwise the first letter of the name.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 56,
  });
  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final src = Env.mediaUrl(url);
    final initial = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Tokens.tint,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
        style: Type.display(size * .4, color: Tokens.primaryText),
      ),
    );
    if (src == null) return initial;
    return ClipOval(
      child: Image.network(
        src,
        key: ValueKey(src),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => initial,
        frameBuilder: (c, child, frame, sync) =>
            frame == null && !sync ? initial : child,
      ),
    );
  }
}
