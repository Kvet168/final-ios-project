import 'package:google_sign_in/google_sign_in.dart';

import '../../core/network/api_client.dart';

/// A sign-in problem the user can understand; shown as-is in a snackbar.
class SocialAuthException implements Exception {
  SocialAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Gets a Google ID token for the WAYFARER server to verify. The server says whether Google sign-in is on and which
/// web client ID its tokens must be issued for, so the app needs no Google configuration of its own beyond the platform files
/// (the iOS client ID in Info.plist, the Android client in Google Cloud).
class GoogleAuth {
  static bool _ready = false;

  /// Returns the ID token, or null when the user closes the Google sheet.
  static Future<String?> idToken(ApiClient api) async {
    final providers = await api.getJson('/auth/providers');
    final google = providers['google'];
    if (google is! Map || google['enabled'] != true) {
      throw SocialAuthException('Google sign-in is not set up yet. Use your email and password for now.');
    }
    final gs = GoogleSignIn.instance;
    if (!gs.supportsAuthenticate()) {
      throw SocialAuthException('Google sign-in is available in the iOS and Android apps. Use your email and password here.');
    }
    try {
      if (!_ready) {
        await gs.initialize(serverClientId: google['clientId'] as String?);
        _ready = true;
      }
      final account = await gs.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) throw SocialAuthException('Google did not return a sign-in token. Please try again.');
      return token;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw SocialAuthException('Google sign-in could not finish (${e.code.name}). Please try again.');
    } on SocialAuthException {
      rethrow;
    } catch (_) {
      throw SocialAuthException('Google sign-in is not fully configured for this app yet. Use your email and password for now.');
    }
  }
}
