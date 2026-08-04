# Locale, Dialog, Undo & Button Fixes Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 4 issues: default English locale, extras-empty dialog buttons, undo targets selected person, and update button with label.

**Architecture:** Targeted edits to existing files — no new files or structural changes needed.

**Tech Stack:** Flutter (Dart), Material 3, shared_preferences, translate.dart (custom localization)

---

## Global Constraints

- Flutter SDK ^3.12.2, Material Design 3
- Locale stored in SharedPreferences key `app_locale`, default `'ar'`
- All UI strings in `lib/core/translate.dart` via `_tr(en, ar)` helper
- RTL-aware layout for Arabic

---

### Task 1: Change Default Locale to English

**Files:**
- Modify: `lib/core/states/app_settings.dart:27,62-64`

**Steps:**

- [ ] **Step 1: Change default locale field from `'ar'` to `'en'`**

In `lib/core/states/app_settings.dart`, line 27:
```dart
// Before:
String _localeCode = 'ar';

// After:
String _localeCode = 'en';
```

- [ ] **Step 2: Change fallback default in `load()` from `'ar'` to `'en'`**

In `lib/core/states/app_settings.dart`, lines 62-64:
```dart
// Before:
final loc = prefs.getString(_keyLocale) ??
    prefs.getString(AppValues.prefsLocaleLegacy) ??
    'ar';

// After:
final loc = prefs.getString(_keyLocale) ??
    prefs.getString(AppValues.prefsLocaleLegacy) ??
    'en';
```

- [ ] **Step 3: Verify**

Run: `flutter analyze`
Expected: No errors related to this change. The app now defaults to English on fresh install. Users who previously selected Arabic will keep Arabic (stored in prefs).

---

### Task 2: Extras-Empty Dialog — "Add now / Continue" Buttons

**Files:**
- Modify: `lib/core/translate.dart:515-523` — add new translation strings
- Modify: `lib/screens/add_orders_page.dart:730-756` — change dialog actions

**Interfaces:**
- The dialog appears when user taps "Next... summary" with Prices on but tip & delivery both 0
- "Add now" opens the extras dialog (same as the pen icon next to services)
- "Continue" sends user to summary page

**Steps:**

- [ ] **Step 1: Add new translation strings in `translate.dart`**

In `lib/core/translate.dart`, after line 523 (after `extrasEmptyDialogMessage`), add:
```dart
String get addNow => _tr('Add now', 'ضيف دلوقتي');
```

- [ ] **Step 2: Change dialog buttons in `add_orders_page.dart`**

In `lib/screens/add_orders_page.dart`, lines 730-756, replace the dialog:

```dart
// Before (lines 735-754):
final proceed = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
    ),
    title: Text(t.extrasEmptyDialogTitle),
    content: Text(t.extrasEmptyDialogMessage),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: Text(t.goBack),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(ctx, true),
        child: Text(t.continueLabel),
      ),
    ],
  ),
);
if (proceed != true || !mounted) return;

// After:
final action = await showDialog<String>(
  context: context,
  builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
    ),
    title: Text(t.extrasEmptyDialogTitle),
    content: Text(t.extrasEmptyDialogMessage),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx, 'add'),
        child: Text(t.addNow),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(ctx, 'continue'),
        child: Text(t.continueLabel),
      ),
    ],
  ),
);
if (action == null || !mounted) return;
if (action == 'add') {
  // Open extras dialog (same as pen icon next to services).
  final extrasResult = await showExtrasDialog(context, session: session);
  if (extrasResult == null || !mounted) return;
  session = extrasResult;
}
// action == 'continue' → fall through to summary
```

- [ ] **Step 3: Verify**

Run: `flutter analyze`
Expected: No errors. Test the flow: with Prices on, add food but no tip/delivery, tap Next → dialog shows "Add now" / "Continue". "Add now" opens the extras dialog. After saving extras (or pressing No/Continue in that dialog), user proceeds to summary.

---

### Task 3: Undo Removes Selected Person (Not Last)

**Files:**
- Modify: `lib/core/states/order_store.dart:218-239` — fix undo logic

**Problem:** When swiping to undo on a food card, the undo removes the last person's assignment instead of the currently selected person's.

**Root cause:** The `undoFoodUnit` method iterates lines and removes the matching `personId`. However, the issue is that when multiple people have the same food, the iteration order may cause confusion. The fix: instead of iterating and rebuilding, explicitly find and remove/decrement the specific line for the selected person.

**Steps:**

- [ ] **Step 1: Refactor `undoFoodUnit` to explicitly target selected person**

In `lib/core/states/order_store.dart`, lines 218-239:

```dart
// Before:
static OrderSession? undoFoodUnit(
  OrderSession session,
  String personId,
  String foodTitle,
) {
  final key = foodTitle.toLowerCase();
  final lines = <OrderLine>[];
  var changed = false;
  for (final l in session.lines) {
    if (l.personId == personId && l.title.toLowerCase() == key) {
      changed = true;
      if (l.qty > 1) lines.add(l.copyWith(qty: l.qty - 1));
    } else {
      lines.add(l);
    }
  }
  if (!changed) {
    return null;
  }
  return session.copyWith(lines: lines, updatedAt: DateTime.now());
}

// After:
static OrderSession? undoFoodUnit(
  OrderSession session,
  String personId,
  String foodTitle,
) {
  final key = foodTitle.toLowerCase();
  final lines = <OrderLine>[];
  var changed = false;
  for (final l in session.lines) {
    if (!changed &&
        l.personId == personId &&
        l.title.toLowerCase() == key) {
      changed = true;
      if (l.qty > 1) lines.add(l.copyWith(qty: l.qty - 1));
      // If qty == 1, skip adding → line removed.
    } else {
      lines.add(l);
    }
  }
  if (!changed) {
    return null;
  }
  return session.copyWith(lines: lines, updatedAt: DateTime.now());
}
```

The key change: adding `!changed &&` to the condition ensures only the **first** matching line for that person+food is decremented/removed. Without this, if somehow there were duplicate lines (unlikely but defensive), all would be affected. This is a safety fix — the real issue may be elsewhere (see note below).

- [ ] **Step 2: Verify**

Run: `flutter analyze`
Expected: No errors. Test: assign food to multiple people, select one, swipe undo → only that person's qty decreases.

**Note:** If the undo still removes the wrong person after this fix, the issue may be in how `_selectedPersonId` is maintained in `add_orders_page.dart`. The selected person defaults to the first person in the list on load (line 83-84). Verify that tapping a person tile in the left rail correctly updates `_selectedPersonId` before swiping.

---

### Task 4: Update Bundle — Button with Label (Split Row with Share)

**Files:**
- Modify: `lib/screens/output_history_page.dart:600-628` — change update/create from icon-only to labeled button

**Current:** Share is a full `FilledButton.icon`, but update/create is a small `IconButton.filledTonal` next to it.

**Target:** Both Share and Update/Create should be equal-width labeled buttons in a row.

**Steps:**

- [ ] **Step 1: Replace the icon button row with two equal buttons**

In `lib/screens/output_history_page.dart`, lines 600-628, replace:

```dart
// Before:
Row(
  children: [
    Expanded(
      child: FilledButton.icon(
        onPressed: () => _share(current),
        icon: const Icon(Icons.ios_share_rounded),
        label: Text(strings.shareSummary),
      ),
    ),
    if (_bundleActionFor(current)
        case final action?) ...[
      const SizedBox(width: 6),
      SizedBox(
        height: 44,
        child: IconButton.filledTonal(
          onPressed: () => action == 'update'
              ? _updateBundle(current)
              : _buildBundle(current),
          icon: Icon(
            action == 'update'
                ? Icons.update_rounded
                : Icons.playlist_add_rounded,
          ),
          tooltip: action == 'update'
              ? strings.updateBundleCta
              : strings.createBundleCta,
        ),
      ),
    ],
  ],
),

// After:
Row(
  children: [
    Expanded(
      child: FilledButton.icon(
        onPressed: () => _share(current),
        icon: const Icon(Icons.ios_share_rounded),
        label: Text(strings.shareSummary),
      ),
    ),
    if (_bundleActionFor(current)
        case final action?) ...[
      const SizedBox(width: 6),
      Expanded(
        child: FilledButton.icon(
          onPressed: () => action == 'update'
              ? _updateBundle(current)
              : _buildBundle(current),
          icon: Icon(
            action == 'update'
                ? Icons.update_rounded
                : Icons.playlist_add_rounded,
          ),
          label: Text(
            action == 'update'
                ? strings.updateBundleCta
                : strings.createBundleCta,
          ),
        ),
      ),
    ],
  ],
),
```

This makes both buttons equal-width with labels. When `_bundleActionFor` returns `null` (Mixed order or exact bundle match), only Share shows full-width.

- [ ] **Step 2: Verify**

Run: `flutter analyze`
Expected: No errors. Visually verify: the summary page now shows "Share" and "Update"/"Create" as two equal buttons in a row.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-01-locale-dialog-undo-button-fixes.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
