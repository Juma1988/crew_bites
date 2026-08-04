# Crew Bites — Store Readiness Checklist

## Pre-Submission (Complete before first upload)

### Play Console Setup
- [ ] Create app in Play Console with package `com.i1988.crewbites`
- [ ] Reserve package name (one-time $25 fee)
- [ ] Complete content rating questionnaire
- [ ] Fill Data safety section (copy from `store/listing/play_en.txt`)
- [ ] Add privacy policy URL (from GitHub Pages)

### App Store Connect Setup
- [ ] Create app in App Store Connect with bundle ID `com.i1988.crewbites`
- [ ] Update `ios/ExportOptions.plist` with Apple Developer team ID
- [ ] Set up provisioning profiles in Xcode
- [ ] Fill App Privacy nutrition labels

### Screenshots (Required for both stores)
- [ ] Capture 4 phone screenshots on Android device:
  1. Homepage ("Who's eating?")
  2. Friends list with emoji avatars
  3. Food + Prices with bundle selected
  4. Order summary with extras
- [ ] Capture 4 phone screenshots on iPhone:
  1. Same 4 screens as Android
- [ ] Save to `fastlane/metadata/android/en-US/images/phoneScreenshots/`
- [ ] Save to `fastlane/metadata/en-US/screens/` (iOS)

### GitHub Pages (Privacy Policy)
- [ ] Initialize git repository (if not done)
- [ ] Push to GitHub
- [ ] Go to repository Settings → Pages
- [ ] Source: Deploy from branch → main
- [ ] Folder: /docs
- [ ] Save and verify URL works: `https://<username>.github.io/<repo>/privacy.html`

### GitHub Secrets (For CI/CD deployment)
- [ ] `SERVICE_ACCOUNT_JSON_PLAINTEXT` — Google Play service account JSON
- [ ] `SIGNING_KEY_STORE_BASE64` — Base64-encoded upload keystore
- [ ] `SIGNING_KEY_ALIAS` — Keystore alias (e.g., `upload`)
- [ ] `SIGNING_STORE_PASSWORD` — Keystore password
- [ ] `SIGNING_KEY_PASSWORD` — Key password

## First Upload (Manual — required before automation)

### Android (Play Console)
- [ ] Build release AAB: `flutter build appbundle --release`
- [ ] Verify signing: `jarsigner -verify -verbose app/build/outputs/bundle/release/app-release.aab`
- [ ] Go to Play Console → Release → Internal testing
- [ ] Create new release
- [ ] Upload `app-release.aab`
- [ ] Complete store listing (title, description, icon)
- [ ] Add feature graphic
- [ ] Add screenshots
- [ ] Complete app content declarations
- [ ] Publish to internal testing

### iOS (App Store Connect)
- [ ] Open project in Xcode
- [ ] Set development team in Signing & Capabilities
- [ ] Product → Archive
- [ ] Validate App
- [ ] Distribute App → App Store Connect
- [ ] Submit for review

## Post-Upload Verification

### Android
- [ ] Monitor crash-free rate in Play Console
- [ ] Test on 3-5 devices via internal track
- [ ] Wait 3-7 days crash-free
- [ ] Gradual rollout: 1% → 10% → 50% → 100%

### iOS
- [ ] Monitor crash reports in App Store Connect
- [ ] Test on 3-5 devices via TestFlight
- [ ] Submit for App Review
- [ ] Wait for approval (typically 24-48 hours)

## Version Management

```bash
# Bump version for new release
./scripts/version-manager.sh patch  # 1.0.0 → 1.0.1
./scripts/version-manager.sh minor  # 1.0.1 → 1.1.0
./scripts/version-manager.sh major  # 1.1.0 → 2.0.0
```

## Deployment Commands

```bash
# Build release
flutter build appbundle --release  # Android
flutter build ios --release         # iOS

# Deploy via Fastlane (after first manual upload)
bundle exec fastlane deploy_internal
```

## Troubleshooting

### "Package not found" in Play Console
- Ensure app exists with exact package name `com.i1988.crewbites`
- Complete first manual upload before using API

### "Upload key mismatch"
- Use Play Console → App signing → Request upload key reset
- Re-upload with correct keystore

### Screenshots not uploading
- Check aspect ratio (16:9 for phone)
- Check file size (max 15MB per image)
- Check format (PNG or JPEG)

### GitHub Pages not working
- Ensure repo is public (or has GitHub Pages enabled)
- Check branch/folder settings
- Wait 5-10 minutes for propagation
