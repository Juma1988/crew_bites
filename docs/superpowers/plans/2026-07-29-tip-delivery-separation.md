# Tip/Delivery Separation + Store Readiness TODO

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Revert tip/delivery merge (make them separate items again) + create a comprehensive store readiness checklist.

**Architecture:** Two separate food items ("Tip" and "Delivery") instead of single "Extras". Each has its own price, stored separately in `foodPrices`. Summary shows both individually.

**Tech Stack:** Flutter/Dart

---

## Task 1: Revert AppValues — Two Separate Keys

**Files:**
- Modify: `lib/core/values/app_values.dart:147-152`

**Interfaces:**
- Produces: `tipItemKey` and `deliveryItemKey` constants

- [ ] **Step 1: Replace extrasItemKey with two keys**

```dart
// ── Special food item keys (order-level, not per-person) ────────────

static const String tipItemKey = 'tip';
static const String deliveryItemKey = 'delivery';

/// Keys that represent order-level extras (tip, delivery).
static const Set<String> specialFoodKeys = {tipItemKey, deliveryItemKey};
```

- [ ] **Step 2: Verify no compile errors**

Run: `flutter analyze`
Expected: 0 issues

---

## Task 2: Revert Translate — Two Food Titles

**Files:**
- Modify: `lib/core/translate.dart` (foodTitle method)

**Interfaces:**
- Consumes: `tipItemKey`, `deliveryItemKey`
- Produces: Updated `foodTitle()` with both keys

- [ ] **Step 1: Update foodTitle method**

```dart
String foodTitle(String raw) {
  final key = raw.toLowerCase().trim();
  return switch (key) {
    'tip' => tipLabel,
    'delivery' => deliveryLabel,
    'falafel' => _tr('Falafel', 'فلافل'),
    // ... rest unchanged
  };
}
```

- [ ] **Step 2: Verify no compile errors**

Run: `flutter analyze`
Expected: 0 issues

---

## Task 3: Revert RestaurantGroup — Two Items in Bundles

**Files:**
- Modify: `lib/models/restaurant_group.dart` (specialItems + builtInSeeds)

**Interfaces:**
- Produces: Two items in `specialItems`, two items in each bundle

- [ ] **Step 1: Update specialItems**

```dart
static const List<String> specialItems = [
  AppValues.tipItemKey,
  AppValues.deliveryItemKey,
];
```

- [ ] **Step 2: Update built-in bundles**

Replace `'Extras'` with `'Tip'` and `'Delivery'` in Wemby and Abo fars bundles.

- [ ] **Step 3: Verify no compile errors**

Run: `flutter analyze`
Expected: 0 issues

---

## Task 4: Revert AddOrdersPage — Two Items in Food List

**Files:**
- Modify: `lib/screens/add_orders_page.dart` (_continue method)

**Interfaces:**
- Consumes: `tipItemKey`, `deliveryItemKey`
- Produces: Separate tip and delivery from foodPrices

- [ ] **Step 1: Update _continue method**

```dart
// Read tip/delivery from separate food list items.
final tipPrice = session.foodPrices[AppValues.tipItemKey] ?? 0;
final deliveryPrice = session.foodPrices[AppValues.deliveryItemKey] ?? 0;
session = session.copyWith(
  tipAmount: tipPrice,
  deliveryFee: deliveryPrice,
  updatedAt: DateTime.now(),
);
```

- [ ] **Step 2: Verify no compile errors**

Run: `flutter analyze`
Expected: 0 issues

---

## Task 5: Revert OutputHistoryPage — Two Extras Rows

**Files:**
- Modify: `lib/screens/output_history_page.dart` (extras section + formatSummary)

**Interfaces:**
- Produces: Two `_ExtraRow` widgets, two lines in text summary

- [ ] **Step 1: Update extras section**

Restore two `_ExtraRow` widgets:
- `_ExtraRow(label: strings.tipLabel, amount: current.tipAmount, ...)`
- `_ExtraRow(label: strings.deliveryLabel, amount: current.deliveryFee, ...)`

- [ ] **Step 2: Update formatSummary**

Restore two lines:
- `${t.tipLabel}: ${t.money(session.tipAmount)}`
- `${t.deliveryLabel}: ${t.money(session.deliveryFee)}`

- [ ] **Step 3: Update showMoney condition**

```dart
final showMoney = pricesOn || current.tipAmount > 0 || current.deliveryFee > 0;
```

- [ ] **Step 4: Verify no compile errors**

Run: `flutter analyze`
Expected: 0 issues

---

## Task 6: Revert OrderSession — Two Extras in personExtrasShare

**Files:**
- Modify: `lib/models/order_models.dart` (personExtrasShare)

**Interfaces:**
- Produces: Splits both tipAmount and deliveryFee equally

- [ ] **Step 1: Update personExtrasShare**

```dart
/// Share of tip+delivery for [personId].
/// Split equally among all people on the order.
double personExtrasShare(String personId) {
  final extras = tipAmount + deliveryFee;
  if (extras <= 0) return 0;
  if (people.isEmpty) return 0;
  if (!people.any((p) => p.id == personId)) return 0;
  return extras / people.length;
}
```

- [ ] **Step 2: Verify no compile errors**

Run: `flutter analyze`
Expected: 0 issues

---

## Task 7: Create Store Readiness TODO File

**Files:**
- Create: `store/STORE_READINESS.md`

**Interfaces:**
- Produces: Comprehensive checklist of all manual steps

- [ ] **Step 1: Create the file**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add store/STORE_READINESS.md
git commit -m "docs: add comprehensive store readiness checklist"
```

---

## Summary

After completing all tasks:

| Task | Status | What changes |
|------|--------|--------------|
| AppValues | ✅ | `tipItemKey` + `deliveryItemKey` (was `extrasItemKey`) |
| Translate | ✅ | Two food titles (tip, delivery) |
| RestaurantGroup | ✅ | Two items in bundles |
| AddOrdersPage | ✅ | Two separate prices read from foodPrices |
| OutputHistoryPage | ✅ | Two extras rows in summary |
| OrderSession | ✅ | personExtrasShare splits both |
| STORE_READINESS.md | ✅ | Comprehensive checklist |

## Verification

Run: `flutter analyze`
Expected: 0 issues

Run: `flutter test`
Expected: All tests pass
