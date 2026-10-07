# CJE 1.1.0 (build 16) — final code and release notes

This folder is the exact source used for the store builds of version **1.1.0, build 16**. It is your build-16 ZIP with the small changes listed below. Signing keys, passwords, caches and generated build files are not included.

## Changes compared with your build-16 ZIP

1. **"Continue with Apple" is shown on iOS only.**
   `lib/views/screens/auth/login_screen.dart` and `register_screen.dart`.
   Sign in with Apple is only required by Apple on iOS and is not configured for Android, which caused the error you saw on Android. Nothing changes on iPhone.

2. **iOS Podfile: all CocoaPods targets set to iOS 15.5.**
   `ios/Podfile` (one line in `post_install`). Xcode 27 refuses to archive pods that target iOS older than 15. This matches the app's own minimum (15.5). `ios/Podfile.lock` was refreshed by `pod install` accordingly.

3. **Removed an unused file:** `android/app/src/main/kotlin/com/chawla/cje/MainActivity.kt`.
   The app uses `com/cje/android/MainActivity.kt`; the old one was never referenced.

`changes.patch` (next to this file) contains the exact code differences for items 1 and 2.

## How the builds were made

- Flutter **3.41.9** / Dart **3.11.5**, `sign_in_with_apple` 8.1.0
- `flutter pub get`, `flutter test` — all **93 tests passed**
- Android: `flutter build appbundle --release --build-name=1.1.0 --build-number=16`
  - package `com.cje.android`, version code 16
  - signed with the original upload key, SHA-1 `49:CA:23:D5:1D:D9:6B:CA:D6:D5:2D:B6:14:32:95:CD:49:13:BC:01`
- iOS: `flutter build ipa --release --build-name=1.1.0 --build-number=16`, Xcode 27
  - bundle `com.cje.ios`, team `C4X5XS5843`, minimum iOS 15.5
  - Push Notifications (production) and Sign in with Apple included
  - exported with the "CJE iOS App Store" provisioning profile

## Release status

- **iOS:** build 1.1.0 (16) uploaded to App Store Connect (2 October 2026) after the Free Apps Agreement was accepted.
- **Android:** release AAB (with the Apple-button fix) ready for Play Console Internal testing.

## Still to do before submitting

- App Store: select build 16, fill "What's New", update **App Privacy** to match the declarations document, add a verified/approved/onboarded **demo account** in App Review information.
- Google Play: upload the AAB to Internal testing, test the Play-installed build, update **Data Safety**, add the demo account under **App access**, then promote to Production.
- Test the TestFlight build on a real iPhone: Apple sign-in (including hidden email), push notifications, account deletion/Apple revocation.

## Notes for later (not release blockers)

- County passwords are still hardcoded in `register_screen.dart` and `profile_setup_screen.dart`; anyone who decompiles the app can read them. Validating them on the server would be safer.
- Please apply the changes above to your own copy so both sources stay identical.
