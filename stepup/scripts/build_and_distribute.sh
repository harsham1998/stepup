#!/usr/bin/env bash
# StepUp Flutter Beta Distribution Script
#
# Prerequisites:
#   1. Run: flutterfire configure --project=stepup-prod (generates lib/firebase_options.dart)
#   2. Set environment variables: SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
#   3. Install Firebase CLI: npm install -g firebase-tools && firebase login
#   4. Replace FIREBASE_APP_ID_IOS and FIREBASE_APP_ID_ANDROID below
#
# Usage: bash scripts/build_and_distribute.sh

set -e

SUPABASE_URL="${SUPABASE_URL:?SUPABASE_URL is required}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY is required}"
API_BASE_URL="${API_BASE_URL:?API_BASE_URL is required}"
FIREBASE_APP_ID_IOS="${FIREBASE_APP_ID_IOS:?FIREBASE_APP_ID_IOS is required}"
FIREBASE_APP_ID_ANDROID="${FIREBASE_APP_ID_ANDROID:?FIREBASE_APP_ID_ANDROID is required}"

echo "=== Running tests ==="
flutter test

echo "=== Building iOS IPA ==="
flutter build ipa --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

echo "=== Distributing iOS to Firebase App Distribution ==="
firebase appdistribution:distribute \
  build/ios/ipa/stepup.ipa \
  --app "$FIREBASE_APP_ID_IOS" \
  --groups testers \
  --release-notes "StepUp beta build"

echo "=== Building Android APK ==="
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

echo "=== Distributing Android to Firebase App Distribution ==="
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app "$FIREBASE_APP_ID_ANDROID" \
  --groups testers \
  --release-notes "StepUp beta build"

echo "=== Done! Testers will receive email with install link ==="
