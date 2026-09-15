# Restaurant Deals — iOS rebuild

Reconstructed iOS source project using the supplied working Android APK and the previous iOS IPA as behavioral references.

## Reconstructed behavior

- `rdapp://` deep-link handling with `backend` and `code` parameters.
- Dynamic backend URL persisted under `mobileAppBackendUrl`.
- Backend endpoints observed in the Android/iOS builds:
  - `GET /api/mobile-app/config`
  - `POST /api/mobile-app/auth/exchange`
  - `POST /api/mobile-app/auth/token`
- Config fields for web root/redeem URL, maintenance, update metadata.
- Token storage in iOS Keychain.
- WKWebView host and `AvensBridge` message reception.
- GitHub Actions unsigned IPA packaging.

## Integrity / proxy boundary

The Android APK contains Android WebView/Integrity-related components and proxy/WebSocket functionality. This reconstruction does **not** forge Google Play Integrity, emulate an Android integrity token on iOS, or tunnel protected third-party traffic to bypass integrity checks. The bridge reports requests so an authorized iOS-specific integration can be connected to a backend/API you control.

## Build

Push the project to GitHub. The workflow file is exactly:

`.github/workflows/ios-unsigned-build.yml`

Run **Actions → iOS Unsigned Build → Run workflow**. The artifact will be `RestaurantDeals-unsigned.ipa`.

## Backend credentials

The old binary contained an embedded authorization credential. It has intentionally **not** been copied into this source project. If you recover the backend, rotate the old credential and configure a new one rather than reusing a secret extracted from an old distributed binary.
