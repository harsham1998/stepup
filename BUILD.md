# StepUp iOS Build & Install

## Prerequisites

- Flutter SDK installed and on PATH
- Xcode with signing team `J9CLDDS9XV`
- iPhone connected via USB (device ID: `00008120-001E6C6C0101A01E`)

---

## Build Release IPA

```bash
cd /Users/harsha/StepUp/stepup
flutter build ios --release
```

Output: `build/ios/iphoneos/Runner.app`

---

## Install on Device

```bash
xcrun devicectl device install app \
  --device 00008120-001E6C6C0101A01E \
  /Users/harsha/StepUp/stepup/build/ios/iphoneos/Runner.app
```

---

## One-liner (build + install)

```bash
cd /Users/harsha/StepUp/stepup && \
flutter build ios --release && \
xcrun devicectl device install app \
  --device 00008120-001E6C6C0101A01E \
  build/ios/iphoneos/Runner.app
```

---

## API (Railway)

Deploy by pushing to the `stepup-api` remote:

```bash
cd /Users/harsha/StepUp/stepup-api
git add -A && git commit -m "your message"
git push railway main
```

Railway auto-deploys on push. Allow ~2–5 min for the build to go live.

---

## Re-seed the database

```bash
cd /Users/harsha/StepUp/stepup-api
node seed.mjs
```

Requires `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in `.env`.

---

## Useful checks

| Task | Command |
|------|---------|
| Check Flutter doctor | `flutter doctor` |
| List connected devices | `xcrun devicectl list devices` |
| Run debug on simulator | `flutter run` |
| Analyze for lint errors | `flutter analyze` |
