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
