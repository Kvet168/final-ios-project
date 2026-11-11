import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/providers.dart';
import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';

class _Slide {
  const _Slide(this.image, this.eyebrow, this.title, this.italic, this.body);
  final String image, eyebrow, title, italic, body;
}

List<_Slide> _slidesFor(AppLocalizations l) => [
  _Slide(
    'https://x/img/22c5bab2e68b0b85.jpg',
    l.welcome1Eyebrow,
    l.welcome1Title,
    l.welcome1Italic,
    l.welcome1Body,
  ),
  _Slide(
    'https://x/img/a109715f7fe087a1.jpg',
    l.welcome2Eyebrow,
    l.welcome2Title,
    l.welcome2Italic,
    l.welcome2Body,
  ),
  _Slide(
    'https://x/img/b46fbbbac2d9fdbb.jpg',
    l.welcome3Eyebrow,
    l.welcome3Title,
    l.welcome3Italic,
    l.welcome3Body,
  ),
];
const _slideCount = 3;

/// First-run carousel: full-bleed photography, big serif type, one clear action.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _page = PageController();
  int _i = 0;

  Future<void> _finish() async {
    await ref.read(onboardedProvider.notifier).complete();
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _slideCount - 1;
    return StatusTone.light(
      child: Scaffold(
        backgroundColor: Tokens.deepRed,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _page,
              itemCount: _slideCount,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) {
                final s = _slidesFor(context.l10n)[i];
                return AnimatedBuilder(
                  animation: _page,
                  builder: (_, _) {
                    final p = _page.hasClients && _page.position.haveDimensions
                        ? (_page.page ?? 0) - i
                        : 0.0;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.translate(
                          offset: Offset(p * -60, 0),
                          child: Transform.scale(
                            scale: 1.12,
                            child: WImage(
                              s.image,
                              full: true,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        const Scrim(top: true, strength: 0.92),
                        Positioned(
                          left: 28,
                          right: 28,
                          bottom: 170,
                          child: Opacity(
                            opacity: (1 - p.abs() * 1.4).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(p * 80, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.eyebrow.toUpperCase(),
                                    style: Type.label(
                                      12,
                                      color: Tokens.onDarkAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    s.title,
                                    style: Type.display(
                                      46,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    s.italic,
                                    style: Type.display(
                                      46,
                                      color: Tokens.onDarkAccent,
                                      height: 1.05,
                                      italic: true,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    s.body,
                                    style: Type.body(
                                      16,
                                      color: Colors.white.withValues(
                                        alpha: .86,
                                      ),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(context.l10n.skip),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      for (var i = 0; i < _slideCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _i ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _i
                                ? Tokens.onDarkAccent
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      const Spacer(),
                      Pressable(
                        onTap: () => last
                            ? _finish()
                            : _page.nextPage(
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                              ),
                        radius: 99,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            horizontal: last ? 28 : 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Tokens.cta,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Tokens.cta.withValues(alpha: .4),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                last
                                    ? context.l10n.startExploring
                                    : context.l10n.next,
                                style: Type.body(
                                  15,
                                  weight: FontWeight.w800,
                                  color: Tokens.onCta,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Tokens.onCta,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
