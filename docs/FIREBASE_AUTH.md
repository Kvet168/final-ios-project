# Firebase sign-in

Firebase proves who the user is (email and password, Google). The WAYFARER backend then checks the Firebase token and keeps the
user, their role, bookings and wishlist in its own database. Without Firebase settings the app keeps using the server's own accounts.

```
App --(Firebase SDK)--> Firebase Auth --ID token--> POST /api/auth/firebase --> WAYFARER tokens (JWT) --> the rest of the API
```

## 1. Firebase console

1. **Authentication > Sign-in method**: turn on **Email/Password** and **Google** (pick a support email).
2. **Project settings > General > Your apps**: add an **iOS app** with bundle id `com.wayfarer.wayfarer` (and an **Android app**, package
   `com.wayfarer.wayfarer`, plus your SHA-1 for Google sign-in).
3. From the app's config (the downloaded `GoogleService-Info.plist` / `google-services.json` is only a place to read the values from; the app
   does not need the files) copy:

| Setting | Where it is |
|---|---|
| project id | Project settings, top of the page (`PROJECT_ID` in the plist) |
| messaging sender id | `GCM_SENDER_ID` in the plist |
| iOS API key / app id | `API_KEY` / `GOOGLE_APP_ID` in the plist |
| iOS client id | `CLIENT_ID` in the plist (for Google sign-in) |
| Android API key / app id | `current_key` / `mobilesdk_app_id` in `google-services.json` |

## 2. The app

Paste the values as the defaults in `app/lib/core/config/firebase_config.dart`, or pass them with `--dart-define=` at build time.

**iOS, Google sign-in only:** open `app/ios/Runner/Info.plist` and add a URL scheme equal to `REVERSED_CLIENT_ID` from the plist:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>com.googleusercontent.apps.XXXXXXXX</string></array>
  </dict>
</array>
```

## 3. The server (Render)

Add one environment variable and redeploy:

| Key | Value |
|---|---|
| `FIREBASE_PROJECT_ID` | the Firebase project id |

`GET /api/auth/providers` then reports `"firebase": {"enabled": true, ...}`.

## How it behaves

- **Sign up:** Firebase creates the account and emails a verification link. The user opens it, then signs in.
- **Sign in:** Firebase checks the password; the app sends the Firebase token to `/api/auth/firebase` and receives WAYFARER tokens.
- **Existing accounts:** a person who already has a WAYFARER account is linked by email, but only when the address is verified (by the
  link, or by Google). Nobody can take over an account by registering its email unverified.
- **Password reset:** Firebase sends the reset email.
- **Older accounts** created before Firebase have no Firebase password. They can sign in with Google, or use "Create account" with the
  same email: after verifying, they are linked to their existing account and keep their bookings.
