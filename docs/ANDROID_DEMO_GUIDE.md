# WAYFARER: Android demo guide

## Install
1. Build: `cd app && flutter build apk --release --target-platform android-arm64`
2. Copy `app/build/app/outputs/flutter-apk/app-release.apk` to the phone (USB, Drive, or `adb install -r app-release.apk`).
3. Allow "install unknown apps" for the file manager used, then open **WAYFARER**.

The phone needs to reach the API for accounts, bookings, search and the AI. Build with `--dart-define=API_BASE_URL=http://<your-computer-LAN-IP>:8080/api` (or the Android emulator's `http://10.0.2.2:8080/api`) while `docker compose up` runs the backend. Photos and fonts are inside the app. If the connection drops, pages you already opened still load from the on-device cache.

## Before presenting
- Open the app once on the venue Wi-Fi (the launch animation wakes the server and loads the home feed).
- Tap **Try the demo account** on the sign-in screen (customer Maya) to show bookings, wishlist and saved trips.

## Suggested 6-minute flow
| Step | What to show | Talking point |
|---|---|---|
| 1 | Welcome carousel, then **Discover** | 30 destinations, 373 places, 76 stays, offline-capable assets |
| 2 | Tap a destination (Siem Reap, Kyoto, Hoi An) | Parallax gallery, facts, map, places, stays |
| 3 | **Stays** tab: filters, then a stay detail | Real date availability and price breakdown |
| 4 | Reserve a room, pay (simulated), open the **ticket** | Held room countdown, server-verified payment, receipt |
| 5 | Centre **AI orb**: "What is the best time to visit Hoi An?" then a follow-up chip | Intent + destination facts + sources, cards, instant answers |
| 6 | **Trips** tab: "3 days in Kampot, relaxed, two kids" | Itinerary built only from stored places, budget split, route map, editable stops |

## How the AI works (for questions)
- **Guide**: detects the destination and intent (best time, transport, budget, food, stay, etiquette), reads the structured destination record plus the best-matching approved guide sentences, and cites them as `[1] [2]`. If nothing matches it says so instead of guessing. Typical response time: under one second once the server is warm.
- **Planner**: a deterministic rules engine ranks stored places by interest, family suitability and distance, schedules them against opening hours and prices the plan. It is labelled as rules-based.
- A language-model key (`AI_PROVIDER_API_KEY` on the server) is optional: when present, the same grounded context is rewritten as friendlier prose. Nothing changes in the app.

## What was verified on an Android emulator (API 34, x86_64)
Release build installed and driven with touch input against the live API: launch and splash, welcome carousel, Discover, destination page, Stays list and detail with live availability, sign-in (demo account), checkout, simulated payment, ticket, cancellation, AI guide (starter cards and typed questions, cards, follow-ups), AI planner (itinerary, budget split, route map), map with OpenStreetMap tiles. Bugs found this way and fixed: arm64-only APK vs x86 emulator, Carto map tiles requiring an API key, Enter key not sending in the chat box, unreadable status-bar icons on dark headers.
Not tested: a physical phone, location permission ("Near me") and slow mobile networks.

## Honest limitations
- Hotels, restaurants, reviews, bookings and payments are educational sample data; payments are simulated.
- Landmark photos are real Wikimedia Commons images; hotel photos are illustrative photos of the destination and are labelled as such.
- Map tiles need internet. Push notifications are not configured (in-app notifications only).
