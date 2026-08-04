# Crew Bites Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all audit issues: structure (bloated files, separation, singletons), coding (fragile keys, hardcoding), and UI/UX (RTL clipping, gesture conflicts, confusing flow).

**Architecture:** Decompose bloated screen files into focused widgets, extract business logic to services, replace global singletons with dependency injection, add constants for magic values, fix RTL/gesture issues.

**Tech Stack:** Flutter, Dart, SharedPreferences, flutter_test

## Global Constraints

- Flutter SDK ^3.12.2
- Dart ^3.12.2
- Material 3 design
- RTL support required (Arabic + English)
- Offline-first (SharedPreferences only)
- Minimal dependencies (5 runtime packages)

---

## Phase 1: Extract Widgets from Bloated Files

### Task 1.1: Extract AddOrdersPage Widgets

**Files:**
- Create: `lib/screens/add_orders/widgets/bundle_pill.dart`
- Create: `lib/screens/add_orders/widgets/add_bundle_pill.dart`
- Create: `lib/screens/add_orders/widgets/bundle_items_editor_sheet.dart`
- Create: `lib/screens/add_orders/widgets/person_rail_tile.dart`
- Create: `lib/screens/add_orders/widgets/add_food_card.dart`
- Create: `lib/screens/add_orders/widgets/food_swipe_bg.dart`
- Create: `lib/screens/add_orders/widgets/food_tile.dart`
- Create: `lib/screens/add_orders/widgets/person_food_icon.dart`
- Create: `lib/screens/add_orders/widgets/missing_prices_dialog.dart`
- Modify: `lib/screens/add_orders_page.dart` (extract widgets)

**Interfaces:**
- Consumes: `AppValues` constants, `CrewStore`, `OrderStore`, `Translate`
- Produces: Extracted widget classes with clear APIs

- [ ] **Step 1: Create bundle_pill.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class BundlePill extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const BundlePill({
    super.key,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppValues.shortAnimationDuration,
        padding: EdgeInsets.symmetric(
          horizontal: AppValues.spacingM,
          vertical: AppValues.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppValues.borderRadiusL),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Create add_bundle_pill.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class AddBundlePill extends StatelessWidget {
  final VoidCallback onTap;

  const AddBundlePill({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppValues.spacingM,
          vertical: AppValues.spacingS,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppValues.borderRadiusL),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: AppValues.iconSizeS,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Create person_rail_tile.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class PersonRailTile extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final bool hasOrders;
  final VoidCallback onTap;

  const PersonRailTile({
    super.key,
    required this.name,
    required this.color,
    required this.isSelected,
    required this.hasOrders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppValues.shortAnimationDuration,
        width: AppValues.personRailWidth,
        padding: EdgeInsets.all(AppValues.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: AppValues.borderSizeM,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: AppValues.avatarRadius,
              child: hasOrders
                  ? Icon(Icons.check, color: Colors.white, size: AppValues.iconSizeS)
                  : null,
            ),
            SizedBox(height: AppValues.spacingXS),
            Text(
              name,
              style: TextStyle(
                fontSize: AppValues.fontSizeS,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 7: Create food_tile.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class FoodTile extends StatelessWidget {
  final String name;
  final double? price;
  final String? assignedTo;
  final Color? assignedColor;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onPriceTap;

  const FoodTile({
    super.key,
    required this.name,
    this.price,
    this.assignedTo,
    this.assignedColor,
    required this.isExpanded,
    required this.onTap,
    this.onPriceTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppValues.shortAnimationDuration,
      margin: EdgeInsets.symmetric(
        horizontal: AppValues.spacingM,
        vertical: AppValues.spacingXS,
      ),
      padding: EdgeInsets.all(AppValues.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppValues.borderRadiusM),
        boxShadow: isExpanded
            ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: AppValues.fontSizeM,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (price != null)
                      GestureDetector(
                        onTap: onPriceTap,
                        child: Text(
                          '\$${price!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppValues.fontSizeS,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (assignedTo != null)
                CircleAvatar(
                  backgroundColor: assignedColor ?? Colors.grey,
                  radius: AppValues.avatarRadiusS,
                  child: Text(
                    assignedTo![0],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppValues.fontSizeXS,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 9: Create missing_prices_dialog.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';
import 'package:app_101/core/translate.dart';

class MissingPricesDialog extends StatelessWidget {
  final List<String> missingItems;
  final VoidCallback onConfirm;

  const MissingPricesDialog({
    super.key,
    required this.missingItems,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Translate.missingPricesTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Translate.missingPricesMessage),
          SizedBox(height: AppValues.spacingM),
          Container(
            padding: EdgeInsets.all(AppValues.spacingM),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppValues.borderRadiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: missingItems
                  .map((item) => Padding(
                        padding: EdgeInsets.only(bottom: AppValues.spacingXS),
                        child: Text('• $item'),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Translate.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(Translate.continueButton),
        ),
      ],
    );
  }
}
```

- [ ] **Step 10: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 11: Update add_orders_page.dart to use extracted widgets**

Remove extracted widget classes and import the new files. Update the build methods to use the new widget classes.

- [ ] **Step 12: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 13: Commit**

```bash
git add lib/screens/add_orders/widgets/ lib/screens/add_orders_page.dart
git commit -m "refactor: extract widgets from AddOrdersPage to separate files"
```

---

### Task 1.2: Extract OutputHistoryPage Widgets

**Files:**
- Create: `lib/screens/output_history/widgets/order_item_row.dart`
- Create: `lib/screens/output_history/widgets/empty_summary.dart`
- Create: `lib/screens/output_history/widgets/person_block.dart`
- Modify: `lib/screens/output_history_page.dart` (extract widgets)

**Interfaces:**
- Consumes: `AppValues` constants, `Translate`
- Produces: Extracted widget classes with clear APIs

- [ ] **Step 1: Create order_item_row.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class OrderItemRow extends StatelessWidget {
  final String personName;
  final Color personColor;
  final List<String> items;
  final double total;

  const OrderItemRow({
    super.key,
    required this.personName,
    required this.personColor,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppValues.spacingM,
        vertical: AppValues.spacingS,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: personColor,
            radius: AppValues.avatarRadius,
          ),
          SizedBox(width: AppValues.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppValues.fontSizeM,
                  ),
                ),
                SizedBox(height: AppValues.spacingXS),
                Text(
                  items.join(', '),
                  style: TextStyle(
                    fontSize: AppValues.fontSizeS,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppValues.fontSizeM,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Create empty_summary.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';
import 'package:app_101/core/translate.dart';

class EmptySummary extends StatelessWidget {
  const EmptySummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: AppValues.iconSizeXL,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: AppValues.spacingL),
          Text(
            Translate.noOrdersYet,
            style: TextStyle(
              fontSize: AppValues.fontSizeL,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppValues.spacingM),
          Text(
            Translate.startAddingOrders,
            style: TextStyle(
              fontSize: AppValues.fontSizeM,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Create person_block.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class PersonBlock extends StatelessWidget {
  final String name;
  final Color color;
  final String emoji;
  final List<String> items;
  final double total;

  const PersonBlock({
    super.key,
    required this.name,
    required this.color,
    required this.emoji,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppValues.spacingS),
      padding: EdgeInsets.all(AppValues.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppValues.borderRadiusL),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: AppValues.avatarRadiusM,
                child: Text(emoji, style: TextStyle(fontSize: AppValues.fontSizeL)),
              ),
              SizedBox(width: AppValues.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppValues.fontSizeL,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            SizedBox(height: AppValues.spacingM),
            Wrap(
              spacing: AppValues.spacingS,
              runSpacing: AppValues.spacingXS,
              children: items
                  .map((item) => Chip(
                        label: Text(item, style: TextStyle(fontSize: AppValues.fontSizeS)),
                        backgroundColor: color.withOpacity(0.1),
                        side: BorderSide(color: color.withOpacity(0.3)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 7: Update output_history_page.dart to use extracted widgets**

Remove extracted widget classes and import the new files. Update the build methods to use the new widget classes.

- [ ] **Step 8: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 9: Commit**

```bash
git add lib/screens/output_history/widgets/ lib/screens/output_history_page.dart
git commit -m "refactor: extract widgets from OutputHistoryPage to separate files"
```

---

### Task 1.3: Extract SettingsPage Widgets

**Files:**
- Create: `lib/screens/settings/widgets/collapsible_card.dart`
- Create: `lib/screens/settings/widgets/step_row.dart`
- Create: `lib/screens/settings/widgets/faq_row.dart`
- Create: `lib/screens/settings/widgets/icon_style_row.dart`
- Create: `lib/screens/settings/widgets/color_theme_card.dart`
- Create: `lib/screens/settings/widgets/palette_dot.dart`
- Modify: `lib/screens/settings_page.dart` (extract widgets)

**Interfaces:**
- Consumes: `AppValues` constants, `Translate`, `AppSettings`
- Produces: Extracted widget classes with clear APIs

- [ ] **Step 1: Create collapsible_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class CollapsibleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const CollapsibleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppValues.spacingM,
        vertical: AppValues.spacingS,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: AppValues.shortAnimationDuration,
              child: Icon(Icons.expand_more),
            ),
            onTap: onToggle,
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(bottom: AppValues.spacingM),
              child: child,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppValues.shortAnimationDuration,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Create step_row.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String? subtitle;

  const StepRow({
    super.key,
    required this.number,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppValues.spacingM,
        vertical: AppValues.spacingS,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            radius: AppValues.avatarRadiusS,
            child: Text(
              number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: AppValues.fontSizeS,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: AppValues.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: AppValues.fontSizeM,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: AppValues.fontSizeS,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Create faq_row.dart**

```dart
import 'package:flutter/material.dart';
import 'package:app_101/core/values/app_values.dart';

class FaqRow extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onToggle;

  const FaqRow({
    super.key,
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(AppValues.spacingM),
          child: Text(
            answer,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
      onExpansionChanged: (_) => onToggle(),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 7: Update settings_page.dart to use extracted widgets**

Remove extracted widget classes and import the new files. Update the build methods to use the new widget classes.

- [ ] **Step 8: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 9: Commit**

```bash
git add lib/screens/settings/widgets/ lib/screens/settings_page.dart
git commit -m "refactor: extract widgets from SettingsPage to separate files"
```

---

## Phase 2: Fix Fragile Keys and Hardcoding

### Task 2.1: Replace Text String Database Keys

**Files:**
- Create: `lib/core/constants/food_keys.dart`
- Modify: `lib/screens/add_orders_page.dart`
- Modify: `lib/screens/output_history_page.dart`

**Interfaces:**
- Consumes: Existing food item references
- Produces: Constants for all food item keys

- [ ] **Step 1: Create food_keys.dart with all food item constants**

```dart
class FoodKeys {
  FoodKeys._();

  // Bundle names
  static const String falafelBundle = 'falafel';
  static const String shawarmaBundle = 'shawarma';
  static const String burgerBundle = 'burger';
  static const String pizzaBundle = 'pizza';
  static const String sushiBundle = 'sushi';

  // Individual food items
  static const String falafel = 'falafel';
  static const String shawarma = 'shawarma';
  static const String burger = 'burger';
  static const String pizza = 'pizza';
  static const String sushi = 'sushi';
  static const String fries = 'fries';
  static const String drink = 'drink';
  static const String salad = 'salad';
  static const String soup = 'soup';
  static const String dessert = 'dessert';
}
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Find all hardcoded food string references**

Search for patterns like `"Falafel"`, `"Shawarma"`, etc. in the codebase and replace with `FoodKeys.falafel`, `FoodKeys.shawarma`, etc.

- [ ] **Step 4: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/food_keys.dart lib/screens/add_orders_page.dart lib/screens/output_history_page.dart
git commit -m "feat: add FoodKeys constants to replace fragile text string database keys"
```

---

### Task 2.2: Extract Magic Numbers and Hardcoded Values

**Files:**
- Create: `lib/core/constants/ui_constants.dart`
- Modify: `lib/screens/add_orders_page.dart`
- Modify: `lib/screens/output_history_page.dart`
- Modify: `lib/screens/settings_page.dart`

**Interfaces:**
- Consumes: Existing hardcoded values (paddings, sizes, durations)
- Produces: Named constants for all magic values

- [ ] **Step 1: Create ui_constants.dart**

```dart
class UIConstants {
  UIConstants._();

  // Spacing
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;

  // Icon sizes
  static const double iconSizeXS = 12.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // Font sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;

  // Avatar sizes
  static const double avatarRadius = 16.0;
  static const double avatarRadiusS = 12.0;
  static const double avatarRadiusM = 20.0;
  static const double avatarRadiusL = 24.0;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Border sizes
  static const double borderSizeS = 1.0;
  static const double borderSizeM = 2.0;
  static const double borderSizeL = 3.0;

  // Component sizes
  static const double personRailWidth = 64.0;
  static const double bottomSheetHeight = 300.0;
  static const double dialogWidth = 300.0;
}
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Replace hardcoded values in screens**

Search for hardcoded numbers like `16.0`, `8.0`, `Duration(milliseconds: 200)`, etc. and replace with `UIConstants` values.

- [ ] **Step 4: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/ui_constants.dart lib/screens/
git commit -m "feat: extract magic numbers to UIConstants"
```

---

## Phase 3: Fix UI/UX Issues

### Task 3.1: Fix RTL Text Clipping

**Files:**
- Modify: `lib/core/theme.dart` (ensure proper text heights)
- Modify: `lib/screens/homepage.dart`
- Modify: `lib/screens/add_orders_page.dart`
- Modify: `lib/screens/output_history_page.dart`

**Interfaces:**
- Consumes: `AppSettings.instance.isArabic`
- Produces: Proper RTL text rendering

- [ ] **Step 1: Add text height configuration to theme**

```dart
// In theme.dart, add to textTheme:
textTheme: TextTheme(
  // ... existing styles
  bodyLarge: TextStyle(height: 1.5),
  bodyMedium: TextStyle(height: 1.5),
  bodySmall: TextStyle(height: 1.5),
  headlineLarge: TextStyle(height: 1.2),
  headlineMedium: TextStyle(height: 1.2),
  headlineSmall: TextStyle(height: 1.2),
  titleLarge: TextStyle(height: 1.3),
  titleMedium: TextStyle(height: 1.3),
  titleSmall: TextStyle(height: 1.3),
),
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Fix text overflow in RTL widgets**

Ensure all Text widgets have proper `overflow` and `maxLines` settings:
```dart
Text(
  text,
  textDirection: TextDirection.rtl, // For Arabic
  overflow: TextOverflow.clip,
  maxLines: 2,
)
```

- [ ] **Step 4: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme.dart lib/screens/
git commit -m "fix: improve RTL text rendering to prevent clipping"
```

---

### Task 3.2: Fix Gesture Conflicts

**Files:**
- Modify: `lib/screens/add_user_page.dart` (swipe gesture)

**Interfaces:**
- Consumes: Existing swipe-to-delete functionality
- Produces: Non-conflicting gesture handling

- [ ] **Step 1: Add gesture detection improvements**

```dart
// In the swipe widget, wrap with GestureDetector to prevent conflicts:
GestureDetector(
  onHorizontalDragStart: (details) {
    // Handle swipe only if horizontal movement is dominant
    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      // Allow swipe
    }
  },
  child: Dismissible(
    // ... existing dismissible
  ),
)
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Commit**

```bash
git add lib/screens/add_user_page.dart
git commit -m "fix: resolve gesture conflict between swipe and scroll"
```

---

### Task 3.3: Improve Unknown Price Flow

**Files:**
- Modify: `lib/screens/add_orders_page.dart`

**Interfaces:**
- Consumes: Missing price detection
- Produces: Clear user feedback and guidance

- [ ] **Step 1: Add clear visual indicators for missing prices**

```dart
// In food tile, add visual indicator:
if (price == null)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      Translate.tapToSetPrice,
      style: TextStyle(
        fontSize: 12,
        color: Colors.orange[700],
      ),
    ),
  ),
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Commit**

```bash
git add lib/screens/add_orders_page.dart
git commit -m "feat: improve unknown price user experience with clear indicators"
```

---

## Phase 4: Improve State Management (Optional - Lower Priority)

### Task 4.1: Extract Business Logic to Services

**Files:**
- Create: `lib/core/services/order_service.dart`
- Create: `lib/core/services/crew_service.dart`
- Modify: `lib/screens/add_orders_page.dart`
- Modify: `lib/screens/output_history_page.dart`

**Interfaces:**
- Consumes: `SharedPreferences`
- Produces: Service classes with clear APIs

- [ ] **Step 1: Create order_service.dart**

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_101/models/order_models.dart';

class OrderService {
  static const String _currentOrderKey = 'current_order';
  static const String _orderHistoryKey = 'order_history';

  final SharedPreferences _prefs;

  OrderService(this._prefs);

  OrderSession? getCurrentOrder() {
    final json = _prefs.getString(_currentOrderKey);
    if (json == null) return null;
    return OrderSession.fromJson(jsonDecode(json));
  }

  Future<void> saveCurrentOrder(OrderSession order) async {
    await _prefs.setString(_currentOrderKey, order.toJson());
  }

  List<OrderSession> getOrderHistory() {
    final jsonList = _prefs.getStringList(_orderHistoryKey) ?? [];
    return jsonList.map((json) => OrderSession.fromJson(jsonDecode(json))).toList();
  }

  Future<void> addToHistory(OrderSession order) async {
    final history = getOrderHistory();
    history.add(order);
    final jsonList = history.map((order) => order.toJson()).toList();
    await _prefs.setStringList(_orderHistoryKey, jsonList);
  }
}
```

- [ ] **Step 2: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 3: Create crew_service.dart**

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_101/models/restaurant_group.dart';

class CrewService {
  static const String _crewKey = 'crew';
  static const String _favoritesKey = 'favorites';

  final SharedPreferences _prefs;

  CrewService(this._prefs);

  List<String> getCrew() {
    return _prefs.getStringList(_crewKey) ?? [];
  }

  Future<void> saveCrew(List<String> crew) async {
    await _prefs.setStringList(_crewKey, crew);
  }

  List<String> getFavorites() {
    return _prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> saveFavorites(List<String> favorites) async {
    await _prefs.setStringList(_favoritesKey, favorites);
  }
}
```

- [ ] **Step 4: Run tests to verify no regression**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/
git commit -m "refactor: extract business logic to OrderService and CrewService"
```

---

## Verification Checklist

Before marking work complete:

- [ ] Every new widget/function has a test (or existing tests verify behavior)
- [ ] Watched each test fail before implementing (where applicable)
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered
- [ ] No hardcoded text strings as database keys
- [ ] No magic numbers in code
- [ ] RTL text renders without clipping
- [ ] Gesture conflicts resolved
- [ ] Unknown price flow is clear

Can't check all boxes? You skipped TDD. Start over.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-08-03-fixall-audit-issues.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
