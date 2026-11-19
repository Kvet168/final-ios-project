import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/google_logo.dart';
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
          await FirebaseSignIn.signUp(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            email: email,
            password: _pw.text,
          );
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(context.l10n.checkYourEmail),
                content: Text(context.l10n.verificationSent(email)),
                actions: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: () => Navigator.pop(c),
                    child: Text(context.l10n.ok),
                  ),
                ],
              ),
            );
            if (mounted) {
              context.go(
                '/login${widget.next == null ? '' : '?next=${Uri.encodeComponent(widget.next!)}'}',
              );
            }
          }
          if (mounted) setState(() => busy = false);
          return;
        }
        await auth.loginWithFirebase(
          await FirebaseSignIn.signIn(email, _pw.text),
        );
      } else if (widget.register) {
        await auth.register(
          '${_first.text.trim()} ${_last.text.trim()}'.trim(),
          email,
          _pw.text,
        );
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
      showInfo(context, context.l10n.googleNotSetUp);
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
    final nextQ = widget.next == null
        ? ''
        : '?next=${Uri.encodeComponent(widget.next!)}';
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final headerH = top + 220;

    OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
    );
    final fieldTheme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tokens.neutralTint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 21,
        ),
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Brand-red header with soft colour blobs, like a poster.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerH + 40,
              child: Container(
                decoration: const BoxDecoration(gradient: Tokens.dusk),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: -80,
                      top: headerH * 0.34,
                      child: _Blob(
                        size: 190,
                        color: Tokens.star.withValues(alpha: 0.85),
                      ),
                    ),
                    Positioned(
                      right: -56,
                      top: headerH * 0.62,
                      child: _Blob(
                        size: 170,
                        color: Tokens.cta.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: top + 14,
              left: 0,
              right: 0,
              height: 150,
              child: Center(
                child: Text(
                  reg
                      ? context.l10n.createAnAccountTitle
                      : context.l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Type.display(36, color: Colors.white, height: 1.08),
                ),
              ),
            ),
            Positioned(
              top: top + 8,
              left: 12,
              child: GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                onTap: () => context.canPop() ? context.pop() : context.go('/'),
              ),
            ),
            Positioned.fill(
              top: headerH - (kb > 0 ? 120 : 0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Tokens.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + kb + bottom),
                  child: Theme(
                    data: fieldTheme,
                    child: Form(
                      key: _form,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton(
                              onPressed: busy ? null : _google,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleLogo(size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    reg
                                        ? context.l10n.signUpWithGoogle
                                        : context.l10n.signInWithGoogle,
                                    style: Type.body(
                                      16,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      context.l10n.or,
                                      style: Type.body(
                                        14,
                                        color: Tokens.inkMuted,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                            ),
                            if (reg) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _first,
                                      autofillHints: const [
                                        AutofillHints.givenName,
                                      ],
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: InputDecoration(
                                        hintText: context.l10n.firstName,
                                      ),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? context.l10n.required
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _last,
                                      autofillHints: const [
                                        AutofillHints.familyName,
                                      ],
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: InputDecoration(
                                        hintText: context.l10n.lastName,
                                      ),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? context.l10n.required
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _email,
                              autofillHints: const [AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: context.l10n.email,
                              ),
                              validator: (v) =>
                                  _emailRe.hasMatch((v ?? '').trim())
                                  ? null
                                  : context.l10n.enterValidEmailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pw,
                              obscureText: hide,
                              autofillHints: [
                                reg
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: context.l10n.password,
                                helperText: reg
                                    ? context.l10n.passwordHelper
                                    : null,
                                helperMaxLines: 2,
                                suffixIcon: IconButton(
                                  tooltip: hide
                                      ? context.l10n.showPassword
                                      : context.l10n.hidePassword,
                                  icon: Icon(
                                    hide
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(() => hide = !hide),
                                ),
                              ),
                              validator: (v) {
                                final s = v ?? '';
                                if (s.isEmpty) {
                                  return context.l10n.enterPassword;
                                }
                                if (reg &&
                                    (s.length < 10 ||
                                        !RegExp(r'\d').hasMatch(s) ||
                                        !RegExp(r'[a-zA-Z]').hasMatch(s))) {
                                  return context.l10n.passwordRule;
                                }
                                return null;
                              },
                            ),
                            if (!reg)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _forgot(context),
                                  child: Text(context.l10n.forgotPassword),
                                ),
                              ),
                            SizedBox(height: reg ? 22 : 8),
                            FilledButton(
                              onPressed: busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: busy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Tokens.onCta,
                                      ),
                                    )
                                  : Text(
                                      reg
                                          ? context.l10n.createAccount
                                          : context.l10n.signIn,
                                      style: Type.body(
                                        16.5,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            if (reg)
                              Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  context.l10n.termsNotice,
                                  textAlign: TextAlign.center,
                                  style: Type.body(
                                    12.5,
                                    color: Tokens.inkMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  reg
                                      ? context.l10n.haveAccount
                                      : context.l10n.newHere,
                                  style: Type.body(15),
                                ),
                                InkWell(
                                  onTap: () => context.go(
                                    reg ? '/login$nextQ' : '/register$nextQ',
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      reg
                                          ? context.l10n.logInHere
                                          : context.l10n.createAnAccount,
                                      style:
                                          Type.body(
                                            15,
                                            weight: FontWeight.w700,
                                            color: Tokens.primaryText,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Tokens.primaryText,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          title: Text(context.l10n.resetPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: context.l10n.email),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(message!),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(context.l10n.close),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () async {
                try {
                  if (firebase) {
                    await FirebaseSignIn.sendPasswordReset(email.text.trim());
                    set(
                      () => message = context.l10n.resetLinkSent(
                        email.text.trim(),
                      ),
                    );
                    return;
                  }
                  final r = await ref
                      .read(apiProvider)
                      .postJson(
                        '/auth/forgot-password',
                        body: {'email': email.text.trim()},
                      );
                  set(
                    () => message =
                        '${r['message']}${r['demoResetToken'] != null ? '\n\nDemo mode (no email provider): use token ${r['demoResetToken']} via the API /auth/reset-password.' : ''}',
                  );
                } catch (e) {
                  set(() => message = e.toString());
                }
              },
              child: Text(context.l10n.sendResetLink),
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
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
