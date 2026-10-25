import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import 'auth_controller.dart';
import 'firebase_sign_in.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Sign-in and sign-up: a brand-red header with the title, a white sheet over it with Google sign-in, then the email form.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.register, this.next});
  final bool register;
  final String? next;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool busy = false, hide = true;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    ref.invalidate(wishlistProvider);
    if (mounted) context.go(widget.next ?? '/account');
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      final auth = ref.read(authProvider.notifier);
      final email = _email.text.trim();
      if (FirebaseSignIn.ready) {
        if (widget.register) {
          await FirebaseSignIn.signUp(firstName: _first.text.trim(), lastName: _last.text.trim(), email: email, password: _pw.text);
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Check your email'),
                content: Text('We sent a verification link to $email. Open it, then sign in.'),
                actions: [FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 46)), onPressed: () => Navigator.pop(c), child: const Text('OK'))],
              ),
            );
            if (mounted) context.go('/login${widget.next == null ? '' : '?next=${Uri.encodeComponent(widget.next!)}'}');
          }
          if (mounted) setState(() => busy = false);
          return;
        }
        await auth.loginWithFirebase(await FirebaseSignIn.signIn(email, _pw.text));
      } else if (widget.register) {
        await auth.register('${_first.text.trim()} ${_last.text.trim()}'.trim(), email, _pw.text);
      } else {
        await auth.login(email, _pw.text);
      }
      await _finish();
    } on AuthMessage catch (e) {
      if (mounted) showInfo(context, e.message);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    if (!FirebaseSignIn.ready) {
      showInfo(context, 'Google sign-in is not set up yet. Use your email and password for now.');
      return;
    }
    setState(() => busy = true);
    try {
      final token = await FirebaseSignIn.signInWithGoogle();
      if (token != null) {
        await ref.read(authProvider.notifier).loginWithFirebase(token);
        await _finish();
      }
    } on AuthMessage catch (e) {
      if (mounted) showInfo(context, e.message);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.register;
    final nextQ = widget.next == null ? '' : '?next=${Uri.encodeComponent(widget.next!)}';
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final headerH = top + 220;

    OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w));
    final fieldTheme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tokens.neutralTint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 21),
        hintStyle: Type.body(16, color: Tokens.inkMuted),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(Tokens.primary, 1.6),
        errorBorder: border(Tokens.danger, 1.2),
        focusedErrorBorder: border(Tokens.danger, 1.6),
        suffixIconColor: Tokens.inkMuted,
      ),
    );

    return StatusTone.light(
      child: Scaffold(
        backgroundColor: Tokens.primaryText,
        resizeToAvoidBottomInset: false,
        body: Stack(fit: StackFit.expand, children: [
          // Brand-red header with soft colour blobs, like a poster.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerH + 40,
            child: Container(
              decoration: const BoxDecoration(gradient: Tokens.dusk),
              child: Stack(clipBehavior: Clip.hardEdge, children: [
                Positioned(left: -80, top: headerH * 0.34, child: _Blob(size: 190, color: Tokens.star.withValues(alpha: 0.85))),
                Positioned(right: -56, top: headerH * 0.62, child: _Blob(size: 170, color: Tokens.cta.withValues(alpha: 0.85))),
              ]),
            ),
          ),
          Positioned(top: top + 14, left: 0, right: 0, height: 150, child: Center(child: Text(reg ? 'Create an\naccount' : 'Welcome\nback', textAlign: TextAlign.center, style: Type.display(36, color: Colors.white, height: 1.08)))),
          Positioned(top: top + 8, left: 12, child: GlassIconButton(icon: Icons.close_rounded, tooltip: 'Close', onTap: () => context.canPop() ? context.pop() : context.go('/'))),
          Positioned.fill(
            top: headerH - (kb > 0 ? 120 : 0),
            child: Container(
              decoration: const BoxDecoration(color: Tokens.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + kb + bottom),
                child: Theme(
                  data: fieldTheme,
                  child: Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        OutlinedButton(
                          onPressed: busy ? null : _google,
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleG())),
                            const SizedBox(width: 12),
                            Text(reg ? 'Sign up with Google' : 'Sign in with Google', style: Type.body(16, weight: FontWeight.w600)),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(children: [
                            const Expanded(child: Divider()),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('or', style: Type.body(14, color: Tokens.inkMuted))),
                            const Expanded(child: Divider()),
                          ]),
                        ),
                        if (reg) ...[
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: TextFormField(controller: _first, autofillHints: const [AutofillHints.givenName], textInputAction: TextInputAction.next, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'First name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null)),
                            const SizedBox(width: 10),
                            Expanded(child: TextFormField(controller: _last, autofillHints: const [AutofillHints.familyName], textInputAction: TextInputAction.next, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Last name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null)),
                          ]),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(controller: _email, autofillHints: const [AutofillHints.email], keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'Email'), validator: (v) => _emailRe.hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pw,
                          obscureText: hide,
                          autofillHints: [reg ? AutofillHints.newPassword : AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            helperText: reg ? '10+ characters, with letters and a number' : null,
                            helperMaxLines: 2,
                            suffixIcon: IconButton(tooltip: hide ? 'Show password' : 'Hide password', icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => hide = !hide)),
                          ),
                          validator: (v) {
                            final s = v ?? '';
                            if (s.isEmpty) return 'Enter your password';
                            if (reg && (s.length < 10 || !RegExp(r'\d').hasMatch(s) || !RegExp(r'[a-zA-Z]').hasMatch(s))) return 'Use 10+ characters with letters and a number';
                            return null;
                          },
                        ),
                        if (!reg) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _forgot(context), child: const Text('Forgot password?'))),
                        SizedBox(height: reg ? 22 : 8),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Tokens.onCta)) : Text(reg ? 'Create account' : 'Sign in', style: Type.body(16.5, weight: FontWeight.w700)),
                        ),
                        if (reg) Padding(padding: const EdgeInsets.only(top: 18), child: Text('By creating an account you agree to the WAYFARER Terms of Service and Privacy Policy.', textAlign: TextAlign.center, style: Type.body(12.5, color: Tokens.inkMuted, height: 1.5))),
                        const SizedBox(height: 18),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(reg ? 'Have an account? ' : 'New here? ', style: Type.body(15)),
                          InkWell(
                            onTap: () => context.go(reg ? '/login$nextQ' : '/register$nextQ'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(reg ? 'Log in here' : 'Create an account', style: Type.body(15, weight: FontWeight.w700, color: Tokens.primaryText).copyWith(decoration: TextDecoration.underline, decorationColor: Tokens.primaryText)),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _forgot(BuildContext context) async {
    final email = TextEditingController(text: _email.text);
    final firebase = FirebaseSignIn.ready;
    String? message;
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Reset password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () async {
                try {
                  if (firebase) {
                    await FirebaseSignIn.sendPasswordReset(email.text.trim());
                    set(() => message = 'If an account exists for ${email.text.trim()}, a reset link is on its way.');
                    return;
                  }
                  final r = await ref.read(apiProvider).postJson('/auth/forgot-password', body: {'email': email.text.trim()});
                  set(() => message = '${r['message']}${r['demoResetToken'] != null ? '\n\nDemo mode (no email provider): use token ${r['demoResetToken']} via the API /auth/reset-password.' : ''}');
                } catch (e) {
                  set(() => message = e.toString());
                }
              },
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// The multi-colour Google "G".
class _GoogleG extends CustomPainter {
  const _GoogleG();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(center: c, radius: r - stroke / 2);
    Paint arc(Color col) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = col;
    const red = Color(0xFFEA4335), yellow = Color(0xFFFBBC05), green = Color(0xFF34A853), blue = Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.84, math.pi * 0.62, false, arc(red)); // top
    canvas.drawArc(rect, math.pi * 0.78, math.pi * 0.62, false, arc(yellow)); // left
    canvas.drawArc(rect, math.pi * 0.28, math.pi * 0.5, false, arc(green)); // bottom
    canvas.drawArc(rect, -math.pi * 0.22, math.pi * 0.5, false, arc(blue)); // right, down to the bar
    canvas.drawRect(Rect.fromLTWH(c.dx, c.dy - stroke / 2, r - 0.5, stroke), Paint()..color = blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
