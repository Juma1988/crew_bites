# Crew Bites — ship checklist

## Done in repo (2026-07-19)

- [x] Release signing via `android/key.properties` + PKCS12 keystore  
- [x] Secrets gitignored (`key.properties`, `*.p12` / `*.jks`)  
- [x] Offline fonts (Nunito + Fredoka) — no Google Fonts network  
- [x] Privacy policy EN/AR (in-app + `assets/legal/`)  
- [x] Settings: Replay tips, full privacy, support contact, What’s new  
- [x] Launcher icons + adaptive icon + Play 512 / feature graphic  
- [x] Store listing copy EN/AR  
- [x] Widget tests fixed for AR default  
- [x] `url_launcher` for mailto support  

## Store Readiness (2026-07-29)

- [x] Version management (`scripts/version-manager.sh` + `CHANGELOG.md`)  
- [x] Privacy policy hosting (`docs/privacy.html` — enable GitHub Pages)  
- [x] Fastlane setup (`fastlane/` directory with deployment lanes)  
- [x] CI pipeline (`.github/workflows/build.yml`)  
- [x] Release workflow (`.github/workflows/release-internal.yml`)  
- [x] App Store metadata (`store/listing/app_store_en.txt` + `ios/ExportOptions.plist`)  
- [x] Screenshot guide (`docs/SCREENSHOT_GUIDE.md`)  

## You must do in Play Console (human)

1. **Backup** `android/keystore/` + `android/key.properties` offline forever.  
2. Create Play app **com.i1988.crewbites** (or confirm package).  
3. **Play App Signing** — upload AAB signed with this upload key.  
4. **Enable GitHub Pages** — Settings → Pages → Source: main, folder: /docs  
5. Support email: **i1988.support@gmail.com** (`LegalConfig` + listing + privacy markdown).  
6. Fill Data safety from `store/listing/play_en.txt`.  
7. Upload icon 512, feature graphic, **phone screenshots** (capture on device).  
8. Internal testing track → 3–7 days crash-free → staged production (1%→…).  
9. Content rating questionnaire; declare **no ads / no IAP**.  

## You must do for App Store (human)

1. Create App Store Connect app **com.i1988.crewbites**  
2. Update `ios/ExportOptions.plist` with your Apple Developer team ID  
3. Capture screenshots for iPhone 6.7", 6.5", and iPad 12.9"  
4. Fill in App Store metadata from `store/listing/app_store_en.txt`  
5. Set up App Privacy nutrition labels  

## GitHub Secrets required for deployment

- `SERVICE_ACCOUNT_JSON_PLAINTEXT` — Google Play service account JSON  
- `SIGNING_KEY_STORE_BASE64` — Base64-encoded upload keystore  
- `SIGNING_KEY_ALIAS` — Keystore alias (e.g., `upload`)  
- `SIGNING_STORE_PASSWORD` — Keystore password  
- `SIGNING_KEY_PASSWORD` — Key password  

## Build commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
# optional APK smoke:
flutter build apk --release
```

## Version management

```bash
./scripts/version-manager.sh patch  # 1.0.0 → 1.0.1
./scripts/version-manager.sh minor  # 1.0.1 → 1.1.0
./scripts/version-manager.sh major  # 1.1.0 → 2.0.0
```

## Rollout halt rules (suggested)

- Crash-free rate &lt; 99% → halt  
- ANR spike → halt  
- Critical bug in order save/share → halt + hot fix versionCode++  

## Optional later

- Firebase Crashlytics (needs `google-services.json`)  
- Rename Dart package `app_101` → `crewbites`  
