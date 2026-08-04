# Crew Bites — Store Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Crew Bites ready for Google Play Store and Apple App Store submission.

**Architecture:** Single-source versioning in `pubspec.yaml`, Fastlane for automated deployment, GitHub Actions for CI/CD, GitHub Pages for privacy policy hosting.

**Tech Stack:** Flutter, Fastlane, GitHub Actions, GitHub Pages, Ruby (for Fastlane)

---

## Task 1: Version Management Setup

**Files:**
- Create: `CHANGELOG.md`
- Create: `scripts/version-manager.sh`
- Modify: `pubspec.yaml` (no change needed, already correct)

**Interfaces:**
- Produces: `scripts/version-manager.sh` that can bump versions in `pubspec.yaml`

- [ ] **Step 1: Create CHANGELOG.md**

```markdown
# Changelog

All notable changes to Crew Bites will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-29

### Added
- Group food ordering with friends
- Emoji + color friend avatars with favorites
- Restaurant bundles (Wemby, Abo Fars, custom)
- Price tracking with on/off toggle
- Order history (last 3 orders)
- Bilingual support (Arabic + English)
- Spotlight tips on first visit
- Extras (tip + delivery) as food list item
- PDF and text sharing
- Offline-first — no account, no ads, no cloud
```

- [ ] **Step 2: Create version-manager.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

PUBSPEC="pubspec.yaml"

usage() {
  echo "Usage: $0 {major|minor|patch|set <version>}"
  exit 1
}

current_version() {
  grep '^version:' "$PUBSPEC" | head -1 | awk '{print $2}'
}

bump() {
  local type=$1
  local ver
  ver=$(current_version)
  local major minor build
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  build=$(echo "$ver" | cut -d. -f3 | cut -d+ -f1)
  local num
  num=$(echo "$ver" | cut -d+ -f2)

  case "$type" in
    major) major=$((major + 1)); minor=0; build=0 ;;
    minor) minor=$((minor + 1)); build=0 ;;
    patch) build=$((build + 1)) ;;
    *) usage ;;
  esac

  local new_ver="$major.$minor.$build+$((num + 1))"
  sed -i "s/^version: .*/version: $new_ver/" "$PUBSPEC"
  echo "Version bumped: $ver → $new_ver"
}

set_version() {
  local new_ver=$1
  local num
  num=$(grep '^version:' "$PUBSPEC" | head -1 | awk '{print $2}' | cut -d+ -f2)
  sed -i "s/^version: .*/version: $new_ver+$((num + 1))/" "$PUBSPEC"
  echo "Version set to: $new_ver+$((num + 1))"
}

case "${1:-}" in
  major|minor|patch) bump "$1" ;;
  set) set_version "${2:?Version required}" ;;
  *) usage ;;
esac
```

- [ ] **Step 3: Make script executable and test**

Run: `chmod +x scripts/version-manager.sh && ./scripts/version-manager.sh patch`
Expected: Version bumped from 1.0.0+1 to 1.0.1+2

- [ ] **Step 4: Reset version for fresh start**

Run: `sed -i 's/^version: .*/version: 1.0.0+1/' pubspec.yaml`

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md scripts/version-manager.sh
git commit -m "feat: add version management and changelog"
```

---

## Task 2: Privacy Policy Hosting (GitHub Pages)

**Files:**
- Create: `docs/index.html`
- Create: `docs/privacy.html`

**Interfaces:**
- Produces: Public HTTPS URL for privacy policy

- [ ] **Step 1: Create docs/index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Crew Bites</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 700px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #333; }
    h1 { color: #FF6B4A; }
    a { color: #FF6B4A; }
  </style>
</head>
<body>
  <h1>Crew Bites</h1>
  <p>Everyone knows their food.</p>
  <p><a href="privacy.html">Privacy Policy</a></p>
</body>
</html>
```

- [ ] **Step 2: Create docs/privacy.html**

Read `assets/legal/privacy_en.md` and convert to HTML with the same styling. Use a simple markdown-to-HTML approach or hardcode the content.

- [ ] **Step 3: Enable GitHub Pages**

1. Go to repository Settings → Pages
2. Source: Deploy from a branch
3. Branch: main, folder: /docs
4. Save

- [ ] **Step 4: Verify HTTPS URL works**

Run: `curl -s https://<username>.github.io/<repo>/privacy.html | head -5`
Expected: HTML content with privacy policy

- [ ] **Step 5: Commit**

```bash
git add docs/
git commit -m "feat: add privacy policy hosting via GitHub Pages"
```

---

## Task 3: Fastlane Setup

**Files:**
- Create: `Gemfile`
- Create: `fastlane/Appfile`
- Create: `fastlane/Fastfile`
- Create: `fastlane/metadata/android/en-US/full_description.txt`
- Create: `fastlane/metadata/android/en-US/short_description.txt`
- Create: `fastlane/metadata/android/en-US/changelogs/1.txt`

**Interfaces:**
- Produces: Fastlane configuration for Android deployment

- [ ] **Step 1: Create Gemfile**

```ruby
source "https://rubygems.org"

gem "fastlane"
```

- [ ] **Step 2: Install Fastlane**

Run: `bundle install`
Expected: Fastlane installed successfully

- [ ] **Step 3: Create fastlane/Appfile**

```
json_key_file("") # Path to the json secret file - follow README setup
package_name("com.i1988.crewbites") # e.g. com.krausefx.app
```

- [ ] **Step 4: Create fastlane/Fastfile**

```ruby
default_platform(:android)

platform :android do
  desc "Build release AAB"
  lane :build do
    gradle(task: "clean bundleRelease")
  end

  desc "Deploy to internal testing track"
  lane :deploy_internal do
    build
    upload_to_play_store(
      track: "internal",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      skip_upload_metadata: false,
      skip_upload_images: false,
      skip_upload_screenshots: false
    )
  end

  desc "Capture screenshots"
  lane :screenshots do
    gradle(task: "clean assembleDebug")
    screengrab(
      app_package_name: "com.i1988.crewbites",
      use_tests_in_package: "com.i1988.crewbites",
      app_apk_path: "app/build/outputs/apk/debug/app-debug.apk",
      device_serial: ENV["DEVICE_SERIAL"]
    )
  end
end
```

- [ ] **Step 5: Create metadata files**

Copy from `store/listing/play_en.txt` into the fastlane metadata structure.

- [ ] **Step 6: Commit**

```bash
git add Gemfile Gemfile.lock fastlane/
git commit -m "feat: add Fastlane for Android deployment"
```

---

## Task 4: GitHub Actions CI Pipeline

**Files:**
- Create: `.github/workflows/build.yml`

**Interfaces:**
- Produces: CI workflow that runs on push/PR

- [ ] **Step 1: Create .github/workflows/build.yml**

```yaml
name: Build & Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.27.0"
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test

      - name: Build Android APK
        run: flutter build apk --debug

      - name: Build iOS (no codesign)
        run: flutter build ios --debug --no-codesign
```

- [ ] **Step 2: Commit**

```bash
git add .github/
git commit -m "ci: add GitHub Actions build and test workflow"
```

---

## Task 5: GitHub Actions Release Workflow

**Files:**
- Create: `.github/workflows/release-internal.yml`

**Interfaces:**
- Produces: Release workflow triggered by tag push

- [ ] **Step 1: Create .github/workflows/release-internal.yml**

```yaml
name: Release to Internal

on:
  push:
    tags:
      - "v*"

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2"
          bundler-cache: true

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.27.0"
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Test
        run: flutter test

      - name: Decode keystore
        run: echo "${{ secrets.SIGNING_KEY_STORE_BASE64 }}" | base64 -d > android/keystore/upload-keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.SIGNING_STORE_PASSWORD }}
          keyPassword=${{ secrets.SIGNING_KEY_PASSWORD }}
          keyAlias=${{ secrets.SIGNING_KEY_ALIAS }}
          storeFile=keystore/upload-keystore.jks
          EOF

      - name: Deploy to internal
        run: bundle exec fastlane deploy_internal
        env:
          GOOGLE_PLAY_JSON_KEY: ${{ secrets.SERVICE_ACCOUNT_JSON_PLAINTEXT }}
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/release-internal.yml
git commit -m "ci: add release workflow for internal track deployment"
```

---

## Task 6: App Store Metadata (iOS)

**Files:**
- Create: `ios/ExportOptions.plist`
- Create: `store/listing/app_store_en.txt`

**Interfaces:**
- Produces: iOS submission configuration and App Store metadata

- [ ] **Step 1: Create ios/ExportOptions.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
```

- [ ] **Step 2: Create store/listing/app_store_en.txt**

```markdown
# App Store Listing — English

## App Name (30 chars max)
Crew Bites — Group Food Orders

## Subtitle (30 chars max)
Everyone knows their food

## Primary Category
Food & Drink

## Secondary Category
Productivity

## Description
Crew Bites helps friends order food together without the chaos.

Pick who's eating, assign food, turn prices on if you need them, then share a clear list.

FEATURES:
• Friends with emoji + favorites
• Bundles (quick menus)
• Prices on/off
• Last 3 orders in history
• Arabic + English
• Spotlight tips on first visit
• Extras (tip + delivery) as food list item

Your data stays on this phone — no account, no ads, no cloud upload of orders.

Tagline: Everyone knows their food.

## Keywords (100 chars max)
food,order,group,friends,restaurant,delivery,tip,split,bill,Arabic,English

## Promotional Text (170 chars max)
Organize group food orders with friends. Everyone knows who ordered what. No account needed.

## What's New
First public release of Crew Bites.
Group orders: friends → food → summary. Prices, bundles, history, AR+EN.

## Privacy URL
https://<username>.github.io/<repo>/privacy.html

## Support URL
mailto:i1988.support@gmail.com

## Marketing URL (optional)
https://<username>.github.io/<repo>/
```

- [ ] **Step 3: Commit**

```bash
git add ios/ExportOptions.plist store/listing/app_store_en.txt
git commit -m "feat: add App Store metadata and export options"
```

---

## Task 7: Screenshot Capture Guide

**Files:**
- Create: `docs/SCREENSHOT_GUIDE.md`

**Interfaces:**
- Produces: Guide for capturing screenshots on both platforms

- [ ] **Step 1: Create screenshot guide**

```markdown
# Screenshot Capture Guide

## Required Screenshots

### Play Store (phone screenshots)
Minimum 2, recommended 4-8. Capture in 16:9 aspect ratio.

1. **Homepage** — "Who's eating?" with food crew illustration
2. **Friends list** — People selected with emoji avatars
3. **Food + Prices** — Bundle selected, prices visible, people assigned
4. **Summary** — Order list with extras and grand total

### App Store
Minimum 1 per required device size. Capture in device frames.

1. **iPhone 6.7"** — Same 4 screens as above
2. **iPhone 6.5"** — Same 4 screens
3. **iPhone 5.5"** — Same 4 screens (if supporting older devices)
4. **iPad 12.9"** — Landscape versions of the same screens

## Capture Steps

### Android (using Fastlane screengrab)
1. Connect device via USB
2. Enable USB debugging
3. Run: `bundle exec fastlane screenshots`
4. Screenshots saved to `fastlane/metadata/android/en-US/images/phoneScreenshots/`

### Android (manual)
1. Open app on device
2. Navigate to each screen
3. Take screenshot using device buttons
4. Transfer to computer
5. Crop to 16:9 aspect ratio (1080x1920 recommended)

### iOS (using Fastlane snapshot)
1. Connect device via USB
2. Open Xcode, set development team
3. Run: `bundle exec fastlane snapshot`
4. Screenshots saved to `fastlane/metadata/en-US/screens/`

### iOS (manual)
1. Open app on device
2. Navigate to each screen
3. Take screenshot using device buttons
4. Transfer to computer via AirDrop or iTunes

## Naming Convention

### Play Store
- `phoneScreenshots/1.png`
- `phoneScreenshots/2.png`
- `phoneScreenshots/3.png`
- `phoneScreenshots/4.png`

### App Store
- `en-US/iPhone6.7/1.png`
- `en-US/iPhone6.5/1.png`
- `en-US/iPad12.9/1.png`

## Tips
- Use demo data (not real friend names)
- Show prices in EGP (default currency)
- Use light theme for better visibility
- Capture in landscape for iPad
- Ensure status bar is clean (no notifications)
```

- [ ] **Step 2: Commit**

```bash
git add docs/SCREENSHOT_GUIDE.md
git commit -m "docs: add screenshot capture guide"
```

---

## Task 8: Update SHIP.md with New Status

**Files:**
- Modify: `store/SHIP.md`

**Interfaces:**
- Consumes: All completed tasks above

- [ ] **Step 1: Update SHIP.md**

Add new sections for:
- Fastlane setup status
- GitHub Actions status
- Version management status
- Privacy policy hosting URL
- App Store metadata status

- [ ] **Step 2: Commit**

```bash
git add store/SHIP.md
git commit -m "docs: update ship checklist with store readiness status"
```

---

## Summary

After completing all tasks:

| Task | Status | Deliverable |
|------|--------|-------------|
| Version Management | ✅ | `scripts/version-manager.sh` + `CHANGELOG.md` |
| Privacy Policy Hosting | ✅ | GitHub Pages HTTPS URL |
| Fastlane Setup | ✅ | `fastlane/` directory with deployment lanes |
| CI Pipeline | ✅ | `.github/workflows/build.yml` |
| Release Workflow | ✅ | `.github/workflows/release-internal.yml` |
| App Store Metadata | ✅ | `store/listing/app_store_en.txt` + `ios/ExportOptions.plist` |
| Screenshot Guide | ✅ | `docs/SCREENSHOT_GUIDE.md` |

### Next Steps After Completion

1. **Capture screenshots** on physical devices (both platforms)
2. **Enable GitHub Pages** in repository settings
3. **Create GitHub Secrets** for signing and service account
4. **First manual upload** to Play Console (required before automation)
5. **Create App Store Connect** app and upload first build
6. **Set up Firebase Crashlytics** (optional, for crash reporting)
