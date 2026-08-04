# Bundle Deselect, Default Names & Favorites Filter Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Three UX improvements: auto-deselect bundle when all its items are removed, remove default starter names (Alex/Sam/Jordan), and only show favorites when starting a new order.

**Architecture:** Targeted edits to existing files — `crew_store.dart` for roster/favorites logic, `add_orders_page.dart` for bundle deselect, `default.dart` for removing seeds.

**Tech Stack:** Flutter (Dart), Material 3, shared_preferences, custom translate.dart localization

---

## Global Constraints

- Flutter SDK ^3.12.2, Material Design 3
- Locale stored in SharedPreferences key `app_locale`, default `'en'`
- All UI strings in `lib/core/translate.dart` via `_tr(en, ar)` helper
- `RestaurantGroup.freeformId = 'freeform'` represents "no bundle selected"

---

### Task 1: Remove Default Starter Names

**Files:**
- Modify: `lib/data/default.dart` — empty the defaultNames list
- Modify: `lib/core/states/crew_store.dart:60-70` — skip seeding on first install

**Interfaces:**
- `CrewStore.load()` currently seeds Alex/Sam/Jordan when `colors.isEmpty` (first install)
- After this change: first install starts with an empty roster; users add their own friends

**Steps:**

- [ ] **Step 1: Empty the defaultNames list**

In `lib/data/default.dart`, replace:
```dart
List<String> defaultNames = [
  'Alex',
  'Sam',
  'Jordan',
];
```
with:
```dart
List<String> defaultNames = [];
```

- [ ] **Step 2: Skip seeding when defaultNames is empty**

In `lib/core/states/crew_store.dart`, the `load()` method (lines 67-70) currently does:
```dart
if (colors.isEmpty) {
  _seedStarterNames();
  await persistCustom(prefs);
}
```

Change to:
```dart
if (colors.isEmpty && defaultNames.isNotEmpty) {
  _seedStarterNames();
  await persistCustom(prefs);
}
```

This ensures that if there are no default names defined, the roster stays empty on first install. Existing users who already have a saved roster are unaffected (their `colors` won't be empty).

- [ ] **Step 3: Verify**

Run: `flutter analyze` in `C:\src\project\crew_bites`
Expected: No errors. Fresh install → empty roster. Existing users → unchanged.

---

### Task 2: Only Favorites Selected on New Order

**Files:**
- Modify: `lib/core/states/crew_store.dart:77-87` — filter to favorites only

**Interfaces:**
- `CrewStore.load()` has a new-order branch that pre-selects favorites then fills with non-favorites
- After this change: only favorites are selected; non-favorites are not auto-selected

**Steps:**

- [ ] **Step 1: Change new-order selection to only select favorites**

In `lib/core/states/crew_store.dart`, lines 77-87, the current code is:
```dart
if (isNewOrder) {
  // Pre-select favorites first, then any remaining names (capped).
  selected.clear();
  for (final n in names) {
    if (selected.length >= AppValues.maxCrewSelected) break;
    if (isFavorite(n)) selected.add(n);
  }
  for (final n in names) {
    if (selected.length >= AppValues.maxCrewSelected) break;
    if (!selected.contains(n)) selected.add(n);
  }
  await persistCustom(prefs);
}
```

Replace with:
```dart
if (isNewOrder) {
  // Only pre-select favorites — non-favorites stay off for new orders.
  selected.clear();
  for (final n in names) {
    if (selected.length >= AppValues.maxCrewSelected) break;
    if (isFavorite(n)) selected.add(n);
  }
  await persistCustom(prefs);
}
```

The second `for` loop (which filled remaining slots with non-favorites) is removed. On a new order, only favorites appear in the left rail. Users can still manually add more people from the Add User page.

- [ ] **Step 2: Verify**

Run: `flutter analyze` in `C:\src\project\crew_bites`
Expected: No errors. New order → only favorites in left rail. Existing orders → unchanged.

---

### Task 3: Auto-Deselect Bundle When All Items Removed

**Files:**
- Modify: `lib/screens/add_orders_page.dart:428-455` — after removing food, check if bundle should deselect

**Interfaces:**
- `_removeFoodFromMenu(foodTitle)` removes a food from `_foods` list and session
- `_session.groupId` holds the currently selected bundle id
- `RestaurantGroup.freeformId` = `'freeform'` (no bundle selected)
- Need to check if remaining foods (excluding specials) still overlap with the bundle's items

**Steps:**

- [ ] **Step 1: Add bundle deselect check after food removal**

In `lib/screens/add_orders_page.dart`, the `_removeFoodFromMenu` method (lines 428-455). After the line `await _save(session.copyWith(foodPrices: prices, lines: lines));` (line 444), add a check:

```dart
Future<void> _removeFoodFromMenu(
  String foodTitle, {
  bool fromDismissible = false,
}) async {
  // Special items (Tip, Delivery) can't be removed.
  if (_isSpecialFood(foodTitle)) return;
  if (!fromDismissible) AppHaptics.mediumImpact();
  final key = foodTitle.toLowerCase();
  setState(() {
    _foods = _foods.where((f) => f.toLowerCase() != key).toList();
  });
  final session = _session;
  if (session != null) {
    final prices = Map<String, double>.from(session.foodPrices)..remove(key);
    final lines =
        session.lines.where((l) => l.title.toLowerCase() != key).toList();
    var next = session.copyWith(foodPrices: prices, lines: lines);

    // Auto-deselect bundle if none of its items remain in the food list.
    final gid = next.groupId;
    if (gid != null &&
        gid.isNotEmpty &&
        gid != RestaurantGroup.freeformId) {
      final bundle = _groupById(gid);
      if (bundle != null) {
        final nonSpecialFoods = _foods
            .where((f) => !AppValues.specialFoodKeys.contains(f.toLowerCase()))
            .toList();
        final stillHasBundleItems = nonSpecialFoods.any(
          (f) => bundle.items.any((b) => b.toLowerCase() == f.toLowerCase()),
        );
        if (!stillHasBundleItems) {
          next = next.copyWith(
            groupId: RestaurantGroup.freeformId,
            groupName: null,
          );
        }
      }
    }

    await _save(next);
  }
  if (!mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(t.foodRemovedToast),
      behavior: SnackBarBehavior.floating,
      duration: AppValues.snackTiny,
    ),
  );
}
```

The key logic: after removing a food, check if any of the selected bundle's items still exist in the food list (excluding specials). If none remain, reset `groupId` to `freeform` and clear `groupName`. This way the bundle pill becomes unselected, and new items added won't be associated with the old bundle.

- [ ] **Step 2: Verify**

Run: `flutter analyze` in `C:\src\project\crew_bites`
Expected: No errors. Test: select a bundle → all its items appear → swipe them all away → bundle pill becomes unselected → new items added are freeform.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-01-bundle-deselect-default-names-favorites.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
