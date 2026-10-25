import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/firebase_config.dart';

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
  static Future<void> signUp({required String firstName, required String lastName, required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
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
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user!;
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        throw AuthMessage('Please verify your email first. We just sent you a new link: open it, then sign in again.');
      }
      return (await user.getIdToken(true))!;
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(_message(e));
    }
  }

  /// Google sign-in through Firebase; returns a fresh ID token, or null if the user closed the Google sheet.
  static Future<String?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider()..addScope('email');
      final cred = kIsWeb ? await _auth.signInWithPopup(provider) : await _auth.signInWithProvider(provider);
      return await cred.user?.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'popup-closed-by-user' || e.code == 'web-context-canceled' || e.code == 'cancelled-popup-request') return null;
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
    } catch (_) {}
  }

  static String _message(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' => 'An account with this email already exists. Try signing in instead.',
        'invalid-email' => 'That email address does not look right.',
        'weak-password' => 'Choose a stronger password: at least 10 characters with letters and a number.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' => 'Email or password is incorrect.',
        'user-disabled' => 'This account has been disabled. Contact support.',
        'too-many-requests' => 'Too many attempts. Please wait a few minutes and try again.',
        'network-request-failed' => 'No connection. Check your internet and try again.',
        'operation-not-allowed' => 'This sign-in method is not turned on in Firebase yet.',
        'account-exists-with-different-credential' => 'This email is already used with another sign-in method.',
        _ => 'Sign-in failed (${e.code}). Please try again.',
      };
}
