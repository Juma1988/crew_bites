# Crew Bites — Play Store Publishing Data

## App Information

| Field | Value |
|-------|-------|
| **App Name** | Crew Bites |
| **Package Name** | com.i1988.crewbites |
| **Version** | 1.0.5+6 |
| **Release Name** | 1.0.5 |
| **Category** | Food & Drink |
| **Content Rating** | Everyone (complete IARC questionnaire) |

## Store Listing Content

### Short Description (≤80 chars)
```
Track group food orders. Everyone knows who ordered what.
```

### Full Description (≤4000 chars)
```
Crew Bites takes the chaos out of group food orders. Pick who's eating, assign food, toggle prices on or off, and share a crystal-clear summary everyone can read.

Perfect for friend gatherings, office lunches, or family dinners — no account needed, no ads, no cloud. Your data stays on your phone.

✓ Friends with emoji avatars and favorites
✓ Restaurant bundles for quick ordering
✓ Price tracking on or off — your choice
✓ Last 3 orders saved in history
✓ Arabic and English bilingual support
✓ Spotlight tips on first visit
✓ Share as PDF or plain text
✓ Extras — tip and delivery as food items
✓ 100% offline — no sign-up, no tracking

Everyone knows their food. No confusion. No leftovers. No one left out.

Download Crew Bites and make your next group order effortless.
```

### What's New (≤500 chars)
```
Crew Bites 1.0.5 — smarter bill splitting!

• Split tip & delivery equally or by each person's order value
• Round each share to a whole number so totals add up exactly
• Tip as a % of your food subtotal (or pick a suggestion)
• Tap the Tip & delivery card to edit — no long-press
• Reminder to keep unfavorited friends before you order
• Tap the empty friends card to add your first friend
```

### Tags (up to 5)
```
food, ordering, group, friends, bill splitting
```

### Contact Email
```
i1988.support@gmail.com
```

### Privacy Policy
- Offline policy in app: Settings → Privacy
- For Play Console: Host `assets/legal/privacy_en.md` on HTTPS (GitHub Pages)

## Visual Assets

| Asset | File | Status |
|-------|------|--------|
| **App Icon (512×512)** | `store/assets/play_icon_512.png` | ✅ Ready |
| **Feature Graphic (1024×500)** | `store/assets/feature_graphic_1024x500.png` | ✅ Ready |
| **Screenshots (Phone)** | Capture 4 screens: Home, Friends, Food+Prices, Summary | ⏳ Pending |
| **Video** | Optional — YouTube URL only | ⏳ Optional |

## Build Artifact

| File | Path | Size |
|------|------|------|
| **AAB (Release)** | `build/app/outputs/bundle/release/app-release.aab` | 52.8 MB |

## Play Console Configuration

### App Signing
- **Mode:** Google Play managed (recommended)
- **Quantum-ready:** Enabled (beta)
- **Upload Key:** Certificate fingerprint will appear after first upload

### Health Features
- **Selection:** "My app does not have any health features"

### Financial Features
- **Selection:** "My app doesn't provide any financial features"

### Data Safety
- Data collected: App activity (order history, names) — stored on device only
- Data shared: No
- Encrypted in transit: N/A (local storage)
- Users can request deletion: Uninstall / clear app data
- Account required: No
- Ads: No
- In-app purchases: No

## Release Track

| Track | Version | Status | Date |
|-------|---------|--------|------|
| Internal Testing | v1.0.5 | Not reviewed (pending) | Aug 8, 2026 |

## Post-Review Checklist

- [ ] Wait for review approval (email notification)
- [ ] Add internal testers (up to 100 emails)
- [ ] Test on 3-5 devices via internal track
- [ ] Monitor crash-free rate in Play Console
- [ ] Wait 3-7 days crash-free
- [ ] Gradual rollout: 1% → 10% → 50% → 100%

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

## App Signing Certificate (Digital Asset Links)

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.i1988.crewbites",
      "sha256_cert_fingerprints":
        ["B6:8F:35:DE:86:20:62:66:2B:BA:BF:B5:44:2E:44:0B:89:CD:FE:A4:EA:F0:9B:A0:3A:22:05:7A:8D:48:33:47"]
    }
  }
]
```

---
*Generated on 2026-08-08*