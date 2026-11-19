import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../../core/config/firebase_config.dart';
import '../../l10n/app_localizations.dart';

/// A sign-in problem the user can understand; shown as-is.
class AuthMessage implements Exception {
  AuthMessage(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Firebase Authentication for sign-up, sign-in, Google and password reset. Firebase only proves who the person is: the app then
/// swaps the Firebase ID token for WAYFARER tokens (POST /auth/firebase), so bookings, roles and wishlists stay in the WAYFARER database.
class FirebaseSignIn {
  static bool _ready = false;

  /// True once Firebase started; false when it is not configured (the app then uses the server's own accounts).
  static bool get ready => _ready;

  static Future<bool> init() async {
    if (!FirebaseConfig.configured) return false;
    try {
      await Firebase.initializeApp(options: FirebaseConfig.options);
      _ready = true;
    } catch (e) {
      debugPrint('Firebase not started: $e');
    }
    return _ready;
  }

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Creates the account, stores the display name and sends the verification email. The user must open that link before signing in.
  static Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName('$firstName $lastName'.trim());
      await user.sendEmailVerification();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(_message(e));
    }
  }

  /// Signs in and returns a fresh ID token. An address that is not verified yet gets a new verification email and an explanation.
  static Future<String> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        throw AuthMessage(_l.verifyEmailFirst);
      }
      return (await user.getIdToken(true))!;
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(_message(e));
    }
  }

  static bool _googleReady = false;

  /// Google sign-in. On phones it uses Google's own sign-in sheet and hands the result to Firebase (no web redirect page, which
  /// browsers with partitioned storage break); on the web it uses Firebase's popup. Returns a fresh ID token, or null if the user
  /// closed the Google sheet.
  static Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final cred = await _auth.signInWithPopup(
          GoogleAuthProvider()..addScope('email'),
        );
        return await cred.user?.getIdToken(true);
      }
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize(
          clientId:
              defaultTargetPlatform == TargetPlatform.iOS &&
                  FirebaseConfig.iosClientId.isNotEmpty
              ? FirebaseConfig.iosClientId
              : null,
        );
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null) throw AuthMessage(_l.authFailed('no-google-token'));
      final cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return await cred.user?.getIdToken(true);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw AuthMessage(_l.authFailed('google-${e.code.name}'));
    } on FirebaseAuthException catch (e) {
      // Firebase spells "cancelled" both ways depending on the platform.
      const closed = {
        'canceled',
        'cancelled',
        'popup-closed-by-user',
        'web-context-canceled',
        'web-context-cancelled',
        'cancelled-popup-request',
      };
      if (closed.contains(e.code)) return null;
      throw AuthMessage(_message(e));
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Do not reveal whether an address has an account.
      if (e.code == 'user-not-found') return;
      throw AuthMessage(_message(e));
    }
  }

  static Future<void> signOut() async {
    if (!_ready) return;
    try {
      await _auth.signOut();
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  // No BuildContext here: messages use the app's current language (set in main.dart).
  static AppLocalizations get _l =>
      lookupAppLocalizations(Locale(Intl.defaultLocale == 'km' ? 'km' : 'en'));

  static String _message(FirebaseAuthException e) => switch (e.code) {
    'email-already-in-use' => _l.authEmailInUse,
    'invalid-email' => _l.authInvalidEmail,
    'weak-password' => _l.authWeakPassword,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'invalid-login-credentials' => _l.authWrongCredentials,
    'user-disabled' => _l.authDisabled,
    'too-many-requests' => _l.authTooMany,
    'network-request-failed' => _l.authNetwork,
    'operation-not-allowed' => _l.authNotAllowed,
    'account-exists-with-different-credential' => _l.authOtherMethod,
    _ => _l.authFailed(e.code),
  };
}
