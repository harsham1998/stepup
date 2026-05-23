# StepUp Flutter App

Dark Neon competitive wellness app — walk to win real money.

## Getting started

### Prerequisites
- Flutter 3.44.0+ with Dart 3.12.0+
- iOS: Xcode 15+ with a physical device or simulator
- Android: Android Studio with an emulator or physical device

### Setup

1. Configure Firebase:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   flutterfire configure --project=stepup-prod
   ```

2. Run the app:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key \
     --dart-define=API_BASE_URL=https://your-railway-app.railway.app
   ```

3. Run tests:
   ```bash
   flutter test
   ```

## Beta distribution

See `scripts/build_and_distribute.sh` for the full build + Firebase App Distribution workflow.

## Architecture

- **State management:** Riverpod (async state) + BLoC (challenge join flow)
- **Navigation:** GoRouter with ShellRoute for bottom nav
- **Step sync:** flutter_background_service (15-min background sync)
- **Health data:** health package (HealthKit on iOS, Health Connect on Android)
- **Payments:** razorpay_flutter
- **Push notifications:** Firebase Cloud Messaging (FCM)
