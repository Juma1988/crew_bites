import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_haptics.dart';
import '../core/debug/debug_registry.dart';
import '../core/states/app_settings.dart';
import '../core/states/bundles_store.dart';
import '../core/states/order_store.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';
import '../models/order_models.dart';
import '../models/restaurant_group.dart';
import '../support/dialog/extras_dialog.dart';
import '../widgets/orders_onboarding.dart';
import '../widgets/prices_toggle_button.dart';
import '../widgets/wizard_step_bar.dart';
import 'add_orders/widgets/add_bundle_pill.dart';
import 'add_orders/widgets/add_food_card.dart';
import 'add_orders/widgets/bundle_items_editor_sheet.dart';
import 'add_orders/widgets/bundle_pill.dart';
import 'add_orders/widgets/food_swipe_bg.dart';
import 'add_orders/widgets/food_tile.dart';
import 'add_orders/widgets/missing_prices_dialog.dart';
import 'add_orders/widgets/person_rail_tile.dart';
import 'add_user_page.dart';
import 'output_history_page.dart';

/// Split layout: people (left) · food menu (right).
/// Bundle pills at top load short placeholder menus.
class AddOrdersPage extends StatefulWidget {
  const AddOrdersPage({super.key});

  static const route = AppValues.routeAddOrders;
  static const String debugSourceFile = 'lib/screens/add_orders_page.dart';

  @override
  State<AddOrdersPage> createState() => _AddOrdersPageState();
}

class _AddOrdersPageState extends State<AddOrdersPage> {
  SharedPreferences? _prefs;
  OrderSession? _session;
  bool _ready = false;

  /// Currently selected person id (left column).
  String? _selectedPersonId;

  /// All restaurant groups (built-in seeds + user edits).
  List<RestaurantGroup> _groups = [];

  /// Food titles for the active place menu.
  List<String> _foods = [];

  final _bundlesKey = GlobalKey();
  final _pricesKey = GlobalKey();
  final _crewKey = GlobalKey();
  final _foodsKey = GlobalKey();
  final _nextKey = GlobalKey();
  final _ordersOnboardingKey = GlobalKey<OrdersOnboardingState>();

  static const t = Translate();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var session = await OrderStore.loadCurrent(
      prefs,
      () => AppSettings.instance.notePrefsCorrupt(),
    );
    final groups = await BundlesStore.load(prefs);
    var foods = OrderStore.foodTitlesFromSession(session);

    // Ensure special items (Tip, Delivery) are always present.
    for (final key in AppValues.specialFoodKeys) {
      final exists = foods.any((f) => f.toLowerCase() == key);
      if (!exists) {
        foods = [...foods, key];
      }
    }

    setState(() {
      _prefs = prefs;
      _session = session;
      _groups = groups;
      _foods = foods;
      _selectedPersonId = session?.people.isNotEmpty == true ? session!.people.first.id : null;
      _ready = true;
    });

    if (!mounted) return;
    if (AppSettings.instance.prefsLoadWarning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.prefsCorruptToast)),
      );
      AppSettings.instance.clearPrefsWarning();
    }
  }

  /// Bundles shown as pills only (Wemby, Abo fars…).
  List<RestaurantGroup> get _bundlePills => BundlesStore.pillsOnly(_groups);

  Future<void> _persistGroups() async {
    await BundlesStore.save(_groups, _prefs);
  }

  void _updateGroup(RestaurantGroup next) {
    setState(() {
      _groups = BundlesStore.replace(_groups, next);
    });
    BundlesStore.save(_groups, _prefs);
  }

  Future<void> _save(OrderSession session) async {
    await OrderStore.saveCurrent(session, _prefs);
    setState(() => _session = session.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> _addFoodToActiveMenu(String name, {double price = 0}) async {
    if (_foods.any((f) => f.toLowerCase() == name.toLowerCase())) {
      return;
    }
    // Insert before the extras item (which should be last) if present.
    final extrasIdx = _foods.indexWhere(
      (f) => AppValues.specialFoodKeys.contains(f.toLowerCase()),
    );
    final newFoods = List<String>.from(_foods);
    if (extrasIdx >= 0) {
      newFoods.insert(extrasIdx, name);
    } else {
      newFoods.add(name);
    }
    setState(() => _foods = newFoods);
    final session = _session;
    if (session != null && price > 0) {
      await _save(OrderStore.setFoodPrice(session, name, price));
    }
  }

  Future<void> _setFoodPrice(String foodTitle, String raw) async {
    final session = _session;
    if (session == null) return;
    final cleaned = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(cleaned) ?? 0;
    await _save(OrderStore.setFoodPrice(session, foodTitle, value));
    // Keep bundle menu prices in sync when user sets a price.
    if (value > 0) {
      await _persistPricesToBundles({foodTitle: value});
    }
  }

  /// Write unit prices onto every saved bundle that lists those foods.
  Future<void> _persistPricesToBundles(Map<String, double> prices) async {
    if (prices.isEmpty) return;
    // Always reload latest prefs so we don't wipe concurrent edits.
    final latest = await BundlesStore.load(_prefs);
    final updated = BundlesStore.applyItemPrices(
      latest,
      prices,
      preferGroupId: _session?.groupId,
    );
    setState(() => _groups = updated);
    await BundlesStore.save(updated, _prefs);
  }

  RestaurantGroup? _groupById(String id) {
    for (final g in _groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  bool _isSpecialFood(String food) => AppValues.specialFoodKeys.contains(food.toLowerCase().trim());

  /// Tap pill: **add** that bundle's items (no toggle / no replace).
  Future<void> _onBundlePillTap(RestaurantGroup bundle) async {
    // Always use latest group from state (after edits).
    final live = _groupById(bundle.id) ?? bundle;
    AppHaptics.mediumImpact();
    final label = live.displayName(arabic: t.isAr);
    final before = _foods.length;
    final merged = OrderStore.mergeFoods(_foods, live.items);

    // Ensure special items are always present AND extras is last.
    final withSpecials = <String>[];
    for (final f in merged) {
      if (!AppValues.specialFoodKeys.contains(f.toLowerCase()) &&
          !withSpecials.any((s) => s.toLowerCase() == f.toLowerCase())) {
        withSpecials.add(f);
      }
    }
    // Add special items at the end, extras last.
    final specials = AppValues.specialFoodKeys.toList();
    for (final key in specials) {
      if (!withSpecials.any((f) => f.toLowerCase() == key)) {
        withSpecials.add(key);
      }
    }
    final added = withSpecials.length - before;

    setState(() => _foods = withSpecials);

    final session = _session;
    if (session != null) {
      final prev = session.groupId;
      final name =
          (prev != null && prev.isNotEmpty && prev != RestaurantGroup.freeformId && prev != live.id)
              ? t.mixedBundleName
              : live.displayName(arabic: t.isAr);
      // Apply saved bundle unit prices onto the current order.
      var next = session.copyWith(
        groupId: live.id,
        groupName: name,
      );
      for (final e in live.itemPrices.entries) {
        if (e.value > 0) {
          // Prefer original title casing from items list when possible.
          final title = live.items.firstWhere(
            (i) => i.toLowerCase() == e.key,
            orElse: () => e.key,
          );
          next = OrderStore.setFoodPrice(next, title, e.value);
        }
      }
      // Apply default extras from the bundle.
      if (live.defaultTax.hasValue) next = next.copyWith(tax: live.defaultTax);
      if (live.defaultService.hasValue) {
        next = next.copyWith(service: live.defaultService);
      }
      if (live.defaultDelivery.hasValue) {
        next = next.copyWith(delivery: live.defaultDelivery);
      }
      await _save(next);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0 ? t.bundleItemsAdded(label, added) : t.bundleItemsAlreadyAdded,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Long-press pill → edit the items this bundle pushes to the food list.
  Future<void> _onBundlePillLongPress(RestaurantGroup bundle) async {
    AppHaptics.mediumImpact();
    final live = _groupById(bundle.id) ?? bundle;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return BundleItemsEditorSheet(
          t: t,
          group: live,
          onChanged: (next) async {
            _updateGroup(next);
            await _persistGroups();
          },
          onDelete: live.isBuiltIn
              ? null
              : () async {
                  setState(() {
                    _groups = BundlesStore.remove(_groups, live.id);
                  });
                  await _persistGroups();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
        );
      },
    );
  }

  /// "+" pill → create a custom bundle, then open item editor.
  Future<void> _onAddBundlePill() async {
    AppHaptics.selectionClick();
    final controller = TextEditingController();
    String? name;
    try {
      name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          title: Text(t.addBundle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: AppValues.maxNameLength,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: t.addBundleHint,
              hintText: t.addBundleNameHint,
              counterText: '',
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(t.save),
            ),
          ],
        ),
      );
    } finally {
      // Defer disposal so the dialog close animation doesn't reference
      // a disposed controller.
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
    if (name == null || name.isEmpty || !mounted) return;

    final look = PersonPalette.randomLook();
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final created = RestaurantGroup(
      id: id,
      nameEn: RestaurantGroup.titleCaseNameOf(name),
      nameAr: RestaurantGroup.titleCaseNameOf(name),
      emoji: look.emoji,
      colorValue: look.color,
      items: const [],
      isBuiltIn: false,
    );
    setState(() => _groups = [..._groups, created]);
    await _persistGroups();
    if (!mounted) return;
    await _onBundlePillLongPress(created);
  }

  Person? get _selectedPerson {
    final s = _session;
    if (s == null || _selectedPersonId == null) return null;
    try {
      return s.people.firstWhere((p) => p.id == _selectedPersonId);
    } catch (_) {
      return null;
    }
  }

  /// People who ordered [foodTitle] (any qty).
  List<OrderLine> _linesForFood(String foodTitle) {
    final s = _session;
    if (s == null) return const [];
    return s.lines.where((l) => l.title.toLowerCase() == foodTitle.toLowerCase()).toList();
  }

  Person? _personById(String id) {
    final s = _session;
    if (s == null) return null;
    try {
      return s.people.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _selectPerson(Person person) {
    AppHaptics.selectionClick();
    setState(() => _selectedPersonId = person.id);
  }

  /// Tap food → +1 for selected person (shows another person icon, not ×2).
  Future<void> _onFoodTap(String foodTitle) async {
    // Special items (Tip, Delivery): tap to edit the value directly.
    if (_isSpecialFood(foodTitle)) {
      await _openEditFoodPriceDialog(foodTitle);
      return;
    }

    final person = _selectedPerson;
    final session = _session;
    if (session == null) return;
    if (person == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.selectPersonFirst)),
      );
      return;
    }

    AppHaptics.selectionClick();
    await _save(
      OrderStore.addFoodUnit(
        session,
        person.id,
        foodTitle,
        unitPrice: session.priceForTitle(foodTitle),
      ),
    );
    if (mounted) {
      _ordersOnboardingKey.currentState?.onFoodAssigned();
    }
  }

  /// Undo one unit for selected person on [foodTitle] (−1).
  Future<bool> _undoFoodForSelected(String foodTitle) async {
    final person = _selectedPerson;
    final session = _session;
    if (session == null) return false;
    if (person == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.selectPersonFirst)),
        );
      }
      return false;
    }

    AppHaptics.mediumImpact();
    final next = OrderStore.undoFoodUnit(session, person.id, foodTitle);
    if (next == null) return false;
    await _save(next);
    return true;
  }

  /// Remove an empty food row from the menu (no one assigned yet).
  /// Prefer calling from [Dismissible.onDismissed] so the swipe + resize
  /// animation can finish first.
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
      final lines = session.lines.where((l) => l.title.toLowerCase() != key).toList();
      // Auto-deselect bundle when none of its items remain in the list.
      var gid = session.groupId;
      var gName = session.groupName;
      if (gid != null && gid.isNotEmpty && gid != RestaurantGroup.freeformId) {
        final bundle = _groupById(gid);
        if (bundle != null) {
          final stillHas = bundle.items.any(
            (bi) => _foods.any((f) => f.toLowerCase() == bi.toLowerCase()),
          );
          if (!stillHas) {
            gid = null;
            gName = null;
          }
        }
      }
      await _save(session.copyWith(
        foodPrices: prices,
        lines: lines,
        groupId: gid,
        groupName: gName,
      ));
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

  /// Zero duration when the user prefers reduced motion.
  Duration _motion(Duration preferred) {
    if (!mounted) return preferred;
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : preferred;
  }

  /// Physical swipe right (LTR start→end, RTL end→start).
  DismissDirection get _undoSwipeDirection {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return rtl ? DismissDirection.endToStart : DismissDirection.startToEnd;
  }

  /// Determine the [ExtrasCategory] that has a value in [session], or return [ExtrasCategory.service] as fallback.
  ExtrasCategory _categoryFromField(OrderSession session) {
    if (session.tip.hasValue) return ExtrasCategory.tip;
    if (session.delivery.hasValue) return ExtrasCategory.delivery;
    if (session.tax.hasValue) return ExtrasCategory.tax;
    return ExtrasCategory.service;
  }

  /// Add food: name always; price field when Prices is on (default 0).
  Future<void> _openAddFoodDialog() async {
    final controller = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    final pricesOn = AppSettings.instance.pricesEnabled;
    ({String name, double price})? result;
    try {
      result = await showDialog<({String name, double price})>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          title: Text(t.addFoodMenu),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: AppValues.maxNameLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: t.foodName,
                  hintText: t.foodNameHint,
                  counterText: '',
                ),
                onSubmitted: (_) {
                  if (!pricesOn) {
                    Navigator.pop(
                      ctx,
                      (name: controller.text.trim(), price: 0.0),
                    );
                  }
                },
              ),
              if (pricesOn) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: t.priceLabel,
                    hintText: t.priceHint,
                    suffixText: t.currencySuffix,
                  ),
                  onSubmitted: (_) {
                    final raw = priceCtrl.text.trim().replaceAll(',', '.');
                    Navigator.pop(
                      ctx,
                      (
                        name: controller.text.trim(),
                        price: double.tryParse(raw) ?? 0.0,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                final raw = priceCtrl.text.trim().replaceAll(',', '.');
                Navigator.pop(
                  ctx,
                  (
                    name: controller.text.trim(),
                    price: pricesOn ? (double.tryParse(raw) ?? 0.0) : 0.0,
                  ),
                );
              },
              child: Text(t.save),
            ),
          ],
        ),
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
        priceCtrl.dispose();
      });
    }
    if (result == null || result.name.isEmpty || !mounted) return;
    await _addFoodToActiveMenu(result.name, price: result.price);
  }

  /// Tap food card → set unit price or edit extras.
  /// For "extras" item, opens 4-field dialog (tip, delivery, tax, service).
  Future<void> _openEditFoodPriceDialog(String foodTitle) async {
    if (!AppSettings.instance.pricesEnabled && !_isSpecialFood(foodTitle)) {
      return;
    }
    final session = _session;
    if (session == null) return;

    // Special handling for extras item: open 4-field dialog.
    if (_isSpecialFood(foodTitle)) {
      final settings = AppSettings.instance;
      final result = await showExtrasDialog(
        context,
        initialCategory: _categoryFromField(session),
        initialTip: session.tip,
        initialDelivery: session.delivery,
        initialTax: session.tax,
        initialService: session.service,
        orderTotal: session.orderTotal,
      );
      if (result == null || !mounted) return;
      AppHaptics.selectionClick();
      // Persist last-used settings for each category that has a value.
      final all = result.allFields;
      if (all[ExtrasCategory.tip]?.hasValue == true) {
        await settings.setLastTip(all[ExtrasCategory.tip]!);
      }
      if (all[ExtrasCategory.tax]?.hasValue == true) {
        await settings.setLastTax(all[ExtrasCategory.tax]!);
      }
      if (all[ExtrasCategory.service]?.hasValue == true) {
        await settings.setLastService(all[ExtrasCategory.service]!);
      }
      // Save extras back to the current bundle.
      if (session.groupId != null && session.groupId!.isNotEmpty) {
        final gid = session.groupId!;
        final bundleIdx = _groups.indexWhere((g) => g.id == gid);
        if (bundleIdx >= 0) {
          var bundle = _groups[bundleIdx];
          if (all[ExtrasCategory.tax]?.hasValue == true) {
            bundle = bundle.copyWith(defaultTax: all[ExtrasCategory.tax]!);
          }
          if (all[ExtrasCategory.service]?.hasValue == true) {
            bundle = bundle.copyWith(defaultService: all[ExtrasCategory.service]!);
          }
          if (all[ExtrasCategory.delivery]?.hasValue == true) {
            bundle = bundle.copyWith(defaultDelivery: all[ExtrasCategory.delivery]!);
          }
          _updateGroup(bundle);
        }
      }
      // Rebuild session with all 4 fields.
      final updatedSession = session.copyWith(
        tip: all[ExtrasCategory.tip],
        delivery: all[ExtrasCategory.delivery],
        tax: all[ExtrasCategory.tax],
        service: all[ExtrasCategory.service],
        updatedAt: DateTime.now(),
      );
      await _save(updatedSession);
      return;
    }

    final current = session.priceForTitle(foodTitle);
    final controller = TextEditingController(
      text: current > 0 ? OrderStore.formatPrice(current) : '0',
    );
    String? raw;
    try {
      raw = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          title: Text(t.editFoodPriceTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: t.priceLabel,
              hintText: t.priceHint,
              suffixText: t.currencySuffix,
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(t.save),
            ),
          ],
        ),
      );
    } finally {
      // Defer disposal so the dialog close animation doesn't reference
      // a disposed controller.
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
    if (raw == null || !mounted) return;
    AppHaptics.selectionClick();
    await _setFoodPrice(foodTitle, raw);
  }

  /// Ordered food titles that still need a unit price.
  /// Explicit map entry (including 0 = “I don’t know”) is treated as set (H1).
  List<String> _foodsMissingPrice(OrderSession session) {
    final missing = <String>[];
    final seen = <String>{};
    for (final l in session.lines) {
      final key = l.title.toLowerCase();
      if (!seen.add(key)) continue;
      if (session.foodPrices.containsKey(key)) continue;
      if (l.price > 0) continue;
      final anyLinePrice = session.lines.any(
        (x) => x.title.toLowerCase() == key && x.price > 0,
      );
      if (!anyLinePrice) missing.add(l.title);
    }
    return missing;
  }

  /// Dialog: fill missing unit prices (or mark unknown), then save on session
  /// **and** on any bundle that contains those foods.
  Future<bool> _promptMissingPrices(
    OrderSession session,
    List<String> foods,
  ) async {
    // Seed dialog fields from any price already known on a bundle.
    final hints = <String, double>{};
    for (final food in foods) {
      final key = food.toLowerCase();
      for (final g in _groups) {
        final p = g.priceForItem(food);
        if (p > 0) {
          hints[key] = p;
          break;
        }
      }
    }

    final result = await showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MissingPricesDialog(
        foods: foods,
        t: t,
        initialPrices: hints,
      ),
    );
    if (result == null || !mounted) return false;

    var next = session;
    for (final e in result.entries) {
      next = OrderStore.setFoodPrice(next, e.key, e.value);
    }
    await _save(next);
    // Persist known prices onto bundles (Wemby, custom, etc.).
    final known = {
      for (final e in result.entries)
        if (e.value > 0) e.key: e.value,
    };
    if (known.isNotEmpty) {
      await _persistPricesToBundles(known);
    }
    return true;
  }

  Future<void> _continue() async {
    final strings = t;
    var session = _session;
    if (session == null || session.people.isEmpty) {
      Navigator.pushReplacementNamed(context, AddUserPage.route);
      return;
    }
    if (session.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.addAtLeastOneItem)),
      );
      return;
    }

    // Warning: people who didn't order anything.
    final s = session;
    final noFoodPeople = s.people.where((p) => s.linesFor(p.id).isEmpty).toList();
    if (noFoodPeople.isNotEmpty) {
      final confirmed = await _showNoFoodWarning(noFoodPeople);
      if (confirmed == null || !mounted) return;
      if (confirmed) {
        // Remove people with no food, keep their lines (none).
        final keepIds = s.people.where((p) => s.linesFor(p.id).isNotEmpty).map((p) => p.id).toSet();
        session = s.copyWith(
          people: s.people.where((p) => keepIds.contains(p.id)).toList(),
        );
        await _save(session);
        if (!mounted) return;
      } else {
        return;
      }
    }

    // When Prices is on, block Next until missing unit prices are filled
    // (or marked unknown). Values are written onto the session so
    // Done & save / history keep the last prices entered.
    if (AppSettings.instance.pricesEnabled) {
      final missing = _foodsMissingPrice(session);
      if (missing.isNotEmpty) {
        final filled = await _promptMissingPrices(session, missing);
        if (!filled || !mounted) return;
        session = _session;
        if (session == null) return;
      }
    }

    // Validate extras: warn if all extras are blank.
    // Only relevant when Prices is on — services are hidden otherwise.
    if (AppSettings.instance.pricesEnabled && session.totalExtras <= 0) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          title: Text(t.extrasEmptyDialogTitle),
          content: Text(t.extrasEmptyDialogMessage),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'add'),
              child: Text(t.addNow),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue'),
              child: Text(t.continueLabel),
            ),
          ],
        ),
      );
      if (action == null || !mounted) return;
      if (action == 'add') {
        final settings = AppSettings.instance;
        final extrasResult = await showExtrasDialog(
          context,
          initialCategory: _categoryFromField(session),
          initialTip: session.tip,
          initialDelivery: session.delivery,
          initialTax: session.tax,
          initialService: session.service,
          orderTotal: session.orderTotal,
        );
        if (extrasResult == null || !mounted) return;
        // Apply all 4 categories.
        final all = extrasResult.allFields;
        if (all[ExtrasCategory.tip]?.hasValue == true) {
          await settings.setLastTip(all[ExtrasCategory.tip]!);
        }
        if (all[ExtrasCategory.tax]?.hasValue == true) {
          await settings.setLastTax(all[ExtrasCategory.tax]!);
        }
        if (all[ExtrasCategory.service]?.hasValue == true) {
          await settings.setLastService(all[ExtrasCategory.service]!);
        }
        // Save extras back to the current bundle.
        if (session.groupId != null && session.groupId!.isNotEmpty) {
          final gid = session.groupId!;
          final bundleIdx = _groups.indexWhere((g) => g.id == gid);
          if (bundleIdx >= 0) {
            var bundle = _groups[bundleIdx];
            if (all[ExtrasCategory.tax]?.hasValue == true) {
              bundle = bundle.copyWith(defaultTax: all[ExtrasCategory.tax]!);
            }
            if (all[ExtrasCategory.service]?.hasValue == true) {
              bundle = bundle.copyWith(defaultService: all[ExtrasCategory.service]!);
            }
            if (all[ExtrasCategory.delivery]?.hasValue == true) {
              bundle = bundle.copyWith(defaultDelivery: all[ExtrasCategory.delivery]!);
            }
            _updateGroup(bundle);
          }
        }
        session = session.copyWith(
          tip: all[ExtrasCategory.tip],
          delivery: all[ExtrasCategory.delivery],
          tax: all[ExtrasCategory.tax],
          service: all[ExtrasCategory.service],
        );
      }
    }

    await _save(session);
    if (!mounted) return;

    AppHaptics.mediumImpact();
    Navigator.pushNamed(context, OutputHistoryPage.route);
  }

  /// Warning dialog for people who didn't order anything.
  /// Returns true = confirm (remove them), false = go back, null = cancel.
  Future<bool?> _showNoFoodWarning(List<Person> people) async {
    final strings = t;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        title: Text(strings.noFoodTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.noFoodBody),
            const SizedBox(height: 12),
            for (final p in people) Text('• ${p.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.goBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirmRemove),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = t;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (DebugRegistry.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugRegistry.currentFile.value = 'lib/screens/add_orders_page.dart';
      });
    }

    if (!_ready) {
      return Scaffold(
        body: Center(
          child: Semantics(
            label: 'Loading',
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final pricesOn = AppSettings.instance.pricesEnabled;
        final session = _session;
        final people = session?.people ?? const <Person>[];
        final pills = _bundlePills;
        final crewIndexById = {
          for (final (i, p) in people.indexed) p.id: i,
        };

        return OrdersOnboarding(
          key: _ordersOnboardingKey,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient(scheme),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 8, 0),
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: MaterialLocalizations.of(context).backButtonTooltip,
                              child: IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                strings.ordersTitle,
                                style: theme.textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            KeyedSubtree(
                              key: _pricesKey,
                              child: const PricesToggleButton(),
                            ),
                          ],
                        ),
                      ),
                      const WizardStepBar(currentStep: 2),
                      // Bundles — pill cells (tap loads placeholder menu)
                      Padding(
                        key: _bundlesKey,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.bundlesLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (var i = 0; i < pills.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    BundlePill(
                                      group: pills[i],
                                      label: pills[i].displayName(
                                        arabic: strings.isAr,
                                      ),
                                      selected: session?.groupId == pills[i].id,
                                      onTap: () => _onBundlePillTap(pills[i]),
                                      onLongPress: () => _onBundlePillLongPress(pills[i]),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  AddBundlePill(
                                    onTap: _onAddBundlePill,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (people.isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: scheme.primaryContainer.withValues(alpha: 0.3),
                                      border: Border.all(
                                        color: scheme.primary.withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      size: 36,
                                      color: scheme.primary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    strings.noCrewOnOrder,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => Navigator.pushReplacementNamed(
                                      context,
                                      AddUserPage.route,
                                    ),
                                    icon: const Icon(Icons.group_add_rounded),
                                    label: Text(strings.goPickCrew),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── LEFT: characters (compact rail) ───────
                                SizedBox(
                                  key: _crewKey,
                                  width: 72,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 2,
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          strings.crewColumn,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount: people.length,
                                          separatorBuilder: (a, b) => const SizedBox(height: 6),
                                          itemBuilder: (context, i) {
                                            final p = people[i];
                                            final selected = p.id == _selectedPersonId;
                                            return PersonRailTile(
                                              person: p,
                                              index: i,
                                              selected: selected,
                                              onTap: () => _selectPerson(p),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // ── RIGHT: foods ──────────────────────────
                                Expanded(
                                  key: _foodsKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          bottom: 8,
                                          right: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              strings.foodColumn,
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (_selectedPerson != null)
                                              Text(
                                                '→ ${_selectedPerson!.name}',
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  color: _selectedPerson!.color,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            // Show the active bundle menu (2–3+ items),
                                            // not only foods already assigned to people.
                                            final menuFoods = List<String>.from(
                                              _foods,
                                            )
                                                .where(
                                                  // Hide the Tip & delivery row when Prices is off.
                                                  (f) =>
                                                      pricesOn ||
                                                      !AppValues.specialFoodKeys.contains(
                                                        f.toLowerCase().trim(),
                                                      ),
                                                )
                                                .toList();
                                            // Always show food rows + a full-width + card.
                                            return ListView.separated(
                                              itemCount: menuFoods.length + 1,
                                              separatorBuilder: (a, b) => const SizedBox(height: 8),
                                              itemBuilder: (context, i) {
                                                if (i == menuFoods.length) {
                                                  return AddFoodCard(
                                                    label: strings.addFoodMenu,
                                                    onTap: _openAddFoodDialog,
                                                  );
                                                }
                                                final food = menuFoods[i];
                                                final lines = _linesForFood(food);
                                                final assignees = <Person>[];
                                                for (final l in lines) {
                                                  final p = _personById(l.personId);
                                                  if (p != null &&
                                                      !assignees.any(
                                                        (x) => x.id == p.id,
                                                      )) {
                                                    assignees.add(p);
                                                  }
                                                }
                                                final qtyByPerson = {
                                                  for (final l in lines) l.personId: l.qty,
                                                };
                                                final undoDir = _undoSwipeDirection;
                                                final isEmptyCard = assignees.isEmpty;
                                                final unitPrice = session?.priceForTitle(food) ?? 0;

                                                return LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final w = constraints.maxWidth;
                                                    final dismissMs = _motion(
                                                      AppValues.animListDismiss,
                                                    );
                                                    return SizedBox(
                                                      width: w,
                                                      child: Dismissible(
                                                        key: ValueKey(
                                                          'food_swipe_$food',
                                                        ),
                                                        direction: undoDir,
                                                        // Slide out, then collapse list gap.
                                                        movementDuration: dismissMs,
                                                        resizeDuration: dismissMs,
                                                        confirmDismiss: (_) async {
                                                          // Special items can't be swiped away.
                                                          if (_isSpecialFood(food)) {
                                                            return false;
                                                          }
                                                          if (isEmptyCard) {
                                                            AppHaptics.mediumImpact();
                                                            // Let Dismissible animate;
                                                            // remove data in onDismissed.
                                                            return true;
                                                          }
                                                          await _undoFoodForSelected(
                                                            food,
                                                          );
                                                          // Snap card back; icons animate via AnimatedSwitcher.
                                                          return false;
                                                        },
                                                        onDismissed: (_) {
                                                          _removeFoodFromMenu(
                                                            food,
                                                            fromDismissible: true,
                                                          );
                                                        },
                                                        background: SizedBox(
                                                          width: w,
                                                          child: FoodSwipeBg(
                                                            label: isEmptyCard
                                                                ? strings.swipeRemoveFood
                                                                : strings.swipeUndoFood,
                                                            icon: isEmptyCard
                                                                ? Icons.delete_outline_rounded
                                                                : Icons.undo_rounded,
                                                            alignStart: undoDir ==
                                                                DismissDirection.startToEnd,
                                                          ),
                                                        ),
                                                        child: SizedBox(
                                                          width: w,
                                                          child: FoodTile(
                                                            title: strings.foodTitle(food),
                                                            // For extras card, show total extras.
                                                            priceText: pricesOn &&
                                                                    ((_isSpecialFood(food) &&
                                                                            (session?.totalExtras ??
                                                                                    0) >
                                                                                0) ||
                                                                        (!_isSpecialFood(food) &&
                                                                            unitPrice > 0))
                                                                ? strings.money(
                                                                    _isSpecialFood(food)
                                                                        ? session!.totalExtras
                                                                        : unitPrice,
                                                                  )
                                                                : null,
                                                            assignees: assignees,
                                                            qtyByPerson: qtyByPerson,
                                                            selectedPersonId: _selectedPersonId,
                                                            hint: strings.tapToAssign,
                                                            showPriceEdit: pricesOn,
                                                            onTap: () => _onFoodTap(food),
                                                            onEditPrice: pricesOn
                                                                ? () => _openEditFoodPriceDialog(
                                                                      food,
                                                                    )
                                                                : null,
                                                            isCompact: _isSpecialFood(food),
                                                            crewIndexById: crewIndexById,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: people.isEmpty
                ? null
                : SafeArea(
                    child: Padding(
                      key: _nextKey,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: FilledButton.icon(
                        onPressed: _continue,
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: Text(strings.continueToSummary),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
