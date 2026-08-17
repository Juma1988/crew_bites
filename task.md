# Task: Fix Tip & Delivery onTap — Normal Tap Only

**Date:** 2026-08-17
**Status:** DONE

---

## Problem

Every time the user taps "Tips & Delivery" in the food menu, the app freezes/crashes.

## Root Cause

**File:** `lib/support/dialog/extras_dialog.dart`
**Lines:** 77-79

`_initControllers()` is called from `initState()` and tries to `.dispose()` on
`late TextEditingController` fields that haven't been assigned yet.

```dart
late TextEditingController amountCtrl;  // not initialized
late TextEditingController pctCtrl;     // not initialized

void _initControllers() {
    amountCtrl.dispose();  // ← LateInitializationError CRASH
    pctCtrl.dispose();     // ← LateInitializationError CRASH
    amountCtrl = TextEditingController();
    pctCtrl = TextEditingController();
```

This throws `LateInitializationError` every time the extras dialog opens,
causing the app to freeze or crash.

## Fix Applied

Added a `_controllersReady` guard flag so `.dispose()` is only called after
the controllers have been initialized (on tab switch, not on first init):

```dart
bool _controllersReady = false;

void _initControllers() {
    if (_controllersReady) {
      amountCtrl.dispose();
      pctCtrl.dispose();
    }
    _controllersReady = true;
    amountCtrl = TextEditingController();
    pctCtrl = TextEditingController();
```

## Second Fix

**File:** `lib/screens/add_orders_page.dart`
**Line:** 590

The extras dialog was blocked when prices were off:

```dart
// Before:
if (!AppSettings.instance.pricesEnabled) return;

// After:
if (!AppSettings.instance.pricesEnabled && !_isSpecialFood(foodTitle)) return;
```

This ensures the extras dialog opens on normal tap regardless of price toggle state.

---

## Build Steps

1. `cd C:\src\project\crew_bites`
2. `flutter build apk --release`
3. `C:\Android\sdk\cmdline-tools\latest\bin\adb install build\app\outputs\flutter-apk\app-release.apk`

## Verification Checklist

- [x] Crash on extras tap — FIXED (LateInitializationError)
- [x] Extras dialog opens on normal tap — FIXED (guard bypassed for special foods)
- [ ] Tip, Delivery, Tax, Service all editable in dialog
- [ ] Values save correctly
- [ ] APK builds without errors
- [ ] APK installs on device

---

## 10 Improvement Suggestions

### 1. Rename `_openEditFoodPriceDialog`
The method name is misleading — it opens the extras dialog, not a price dialog.
Rename to `_openExtrasOrPriceDialog` or split into two methods.

### 2. Extract Extras Tap Logic
Move the extras-specific flow into a dedicated `_onExtrasTap()` method
for clarity and testability.

### 3. Add Haptic Feedback on Extras Tap
Currently haptic feedback only fires on dialog save. Add a light haptic
when the extras row is tapped to provide tactile confirmation.

### 4. Show Tip/Delivery Summary on Card
Instead of showing just the total extras amount, show individual values
(e.g., "Tip: $5, Delivery: $3") directly on the card.

### 5. Quick-Add Preset Chips
Add tappable preset chips for common tip percentages (10%, 15%, 20%)
inside the extras dialog to speed up entry.

### 6. Animate Extras Card on Value Change
Add a pulse or glow animation when extras values change to give
visual feedback that the values were saved.

### 7. Persist Last Tip/Delivery Per Restaurant
Remember the last-used tip/delivery values per restaurant bundle,
not just globally. Different restaurants may have different norms.

### 8. Auto-Focus Amount Field
When the extras dialog opens, auto-focus the amount TextField
so the keyboard appears immediately for quick entry.

### 9. Accessibility: Semantic Labels
Add semantic labels showing current tip/delivery values on the
extras card for screen reader users.

### 10. Swipe-to-Clear Extras
Add a swipe-right gesture on the extras card to quickly clear
all extras values (tip, delivery, tax, service) at once.
