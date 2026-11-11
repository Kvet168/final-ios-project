import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project settings. Copy them from the Firebase console: Project settings > General > Your apps. They are identifiers, not
/// secrets, so they can live in the source. Leave them empty to run without Firebase: the app then signs in with the WAYFARER server's
/// own email and password accounts.
///
/// Each platform has its own API key and app id (add an iOS app with bundle id com.wayfarer.wayfarer, and an Android app with package
/// com.wayfarer.wayfarer). The project id and sender id are shared. Paste the values into the defaults below or pass them at build time:
/// flutter run --dart-define=FIREBASE_PROJECT_ID=... --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_IOS_API_KEY=... --dart-define=FIREBASE_IOS_APP_ID=...
class FirebaseConfig {
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'travel-app-5b220',
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '77263866261',
  );

  static const iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: 'AIzaSyC8fAD-hw79LWakCbPNAcJsvDCLoJGo8YQ',
  );
  static const iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:77263866261:ios:6849a8dfe9c8cd2a238e9c',
  );

  /// The iOS OAuth client id (GoogleService-Info.plist > CLIENT_ID); needed for Google sign-in on iOS.
  static const iosClientId = String.fromEnvironment(
    'FIREBASE_IOS_CLIENT_ID',
    defaultValue: '77263866261-c41oqe6uhmtpm2m72codn4vmi530cohh.apps.googleusercontent.com',
  );

  static const androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: '',
  );
  static const androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '',
  );

  static const webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );
  static const webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '',
  );

  /// Web needs the authDomain, usually `<project-id>.firebaseapp.com` (filled in automatically when empty).
  static const webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: '',
  );

  static String get _apiKey => kIsWeb
      ? webApiKey
      : (defaultTargetPlatform == TargetPlatform.android
            ? androidApiKey
            : iosApiKey);
  static String get _appId => kIsWeb
      ? webAppId
      : (defaultTargetPlatform == TargetPlatform.android
            ? androidAppId
            : iosAppId);

  /// True when this platform has everything Firebase needs.
  static bool get configured =>
      projectId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: kIsWeb
        ? (webAuthDomain.isEmpty ? '$projectId.firebaseapp.com' : webAuthDomain)
        : null,
    iosBundleId: defaultTargetPlatform == TargetPlatform.iOS
        ? 'com.wayfarer.wayfarer'
        : null,
    iosClientId:
        defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isNotEmpty
        ? iosClientId
        : null,
  );
}
