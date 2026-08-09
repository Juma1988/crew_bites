import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_haptics.dart';
import '../core/extras_split_mode.dart';
import '../core/friend_icon_style.dart';
import '../core/states/app_settings.dart';
import '../core/states/bundles_store.dart';
import '../core/states/crew_store.dart';
import '../core/states/order_store.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';
import '../models/order_models.dart';
import '../models/output_args.dart';
import '../models/restaurant_group.dart';
import '../widgets/section_card.dart';
import '../widgets/summary_onboarding.dart';
import '../widgets/wizard_step_bar.dart';
import 'homepage.dart';
import 'add_orders_page.dart';
import 'add_user_page.dart';

/// Final order page: whole-order item totals → who ordered what → save.
/// Pass [OutputHistoryArgs] to open a past history session (F01).
class OutputHistoryPage extends StatefulWidget {
  const OutputHistoryPage({super.key});

  static const route = '/output-history';

  @override
  State<OutputHistoryPage> createState() => _OutputHistoryPageState();
}

class _OutputHistoryPageState extends State<OutputHistoryPage> {
  SharedPreferences? _prefs;
  OrderSession? _current;
  bool _fromHistory = false;
  bool _ready = false;
  bool _argsRead = false;
  List<RestaurantGroup> _groups = [];
  final _wholeOrderKey = GlobalKey();
  final _whoOrderedKey = GlobalKey();
  final _actionsKey = GlobalKey();
  final _summaryOnboardingKey = GlobalKey<SummaryOnboardingState>();
  int _swipeDownCount = 0;
  bool _neonUnlocked = false;
  bool _unlocking = false;
  Timer? _swipeResetTimer;

  static const t = Translate();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OutputHistoryArgs && args.session != null) {
      _fromHistory = args.fromHistory;
      _current = args.session;
      _ready = true;
      SharedPreferences.getInstance().then((p) {
        if (!mounted) return;
        _neonUnlocked = p.getBool(AppValues.prefsNeonUnlocked) ?? false;
        BundlesStore.load(p).then((groups) {
          if (!mounted) return;
          setState(() {
            _prefs = p;
            _groups = groups;
          });
        });
      });
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _swipeResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _neonUnlocked = prefs.getBool(AppValues.prefsNeonUnlocked) ?? false;
    final session = await OrderStore.loadCurrent(
      prefs,
      () => AppSettings.instance.notePrefsCorrupt(),
    );
    final groups = await BundlesStore.load(prefs);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _current = session;
      _groups = groups;
      _fromHistory = false;
      _ready = true;
    });
  }

  /// Resume order again with stack Home → People → Food (same as Continue).
  Future<void> _orderAgain(OrderSession session) async {
    AppHaptics.mediumImpact();
    await OrderStore.restoreAsCurrent(session, _prefs);
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    // People under Food so Back from food returns to people.
    nav.pushNamed(AddUserPage.route);
    await nav.pushNamed(AddOrdersPage.route);
  }

  Future<void> _pushHistory(OrderSession session) async {
    if (!session.hasContent) return;
    final history = await OrderStore.loadHistory(_prefs);
    await OrderStore.pushHistory(session, history, _prefs);
  }

  /// Split mode to apply: by-value only when prices are on, else even.
  ExtrasSplitMode _splitMode(bool pricesOn) =>
      pricesOn ? AppSettings.instance.extrasSplitMode : ExtrasSplitMode.even;

  /// Round per-person shares to whole units when prices are on + setting.
  bool _roundTotals(bool pricesOn) =>
      pricesOn && AppSettings.instance.roundTotals;

  String _formatSummary(OrderSession session) {
    final pricesOn = AppSettings.instance.pricesEnabled;
    final splitMode = _splitMode(pricesOn);
    final roundTotals = _roundTotals(pricesOn);
    final buf = StringBuffer();
    buf.writeln(AppTheme.brandName);
    if (session.hasPlace) buf.writeln(session.groupName);
    buf.writeln('────────────');
    buf.writeln(t.orderItemsTitle);
    for (final a in session.aggregateFoods()) {
      buf.writeln(t.foodUnitsLine(a.title, a.qty));
    }
    buf.writeln('────────────');
    buf.writeln(t.whoOrderedTitle);
    for (final p in session.people) {
      final lines = session.linesFor(p.id);
      if (lines.isEmpty) {
        buf.writeln('${p.name}: ${t.emptyOrder}');
        continue;
      }
      final total = session.personGrandTotalFor(
        p.id,
        mode: splitMode,
        round: roundTotals,
      );
      if (pricesOn && total > 0) {
        buf.writeln('${p.name} - ${t.money(total)}');
      } else {
        buf.writeln(p.name);
      }
      for (final l in lines) {
        final n = l.note.isEmpty ? '' : ' (${l.note})';
        buf.writeln('${l.qty} | ${t.foodTitle(l.title)}$n');
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  Future<void> _share(OrderSession session) async {
    AppHaptics.mediumImpact();
    await SharePlus.instance.share(
      ShareParams(text: _formatSummary(session)),
    );
  }

  /// Save this order’s foods as a named bundle (or merge into an existing one).
  Future<void> _buildBundle(OrderSession session) async {
    final foods = OrderStore.foodTitlesFromSession(session);
    if (foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.buildBundleEmptyFoods)),
      );
      return;
    }

    AppHaptics.selectionClick();
    final nameCtrl = TextEditingController(
      text: session.groupName?.trim().isNotEmpty == true
          ? session.groupName!.trim()
          : '',
    );
    String? name;
    try {
      name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          title: Text(t.buildBundleTitle),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: t.buildBundleHint,
              hintText: t.buildBundleNameHint,
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
              child: Text(t.save),
            ),
          ],
        ),
      );
    } finally {
      // Defer disposal so the dialog close animation doesn't reference
      // a disposed controller.
      WidgetsBinding.instance.addPostFrameCallback((_) => nameCtrl.dispose());
    }
    if (name == null || name.isEmpty || !mounted) return;

    final groups = await BundlesStore.load(_prefs);
    final match = _findBundleByName(groups, name);

    // Prices from this order → bundle itemPrices (lowercase keys).
    final prices = <String, double>{
      for (final f in foods)
        if (session.priceForTitle(f) > 0)
          f.toLowerCase(): session.priceForTitle(f),
    };

    if (match == null) {
      final look = PersonPalette.randomLook();
      final created = RestaurantGroup(
        id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
        nameEn: RestaurantGroup.titleCaseNameOf(name),
        nameAr: RestaurantGroup.titleCaseNameOf(name),
        emoji: look.emoji,
        colorValue: look.color,
        items: List<String>.from(foods),
        itemPrices: prices,
        isBuiltIn: false,
      );
      final next = [...groups, created];
      await BundlesStore.save(next, _prefs);
      if (!mounted) return;
      setState(() => _groups = next);
      AppHaptics.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.buildBundleCreated)),
      );
      return;
    }

    // Existing name → add only foods not already on that bundle (+ prices).
    final missing = <String>[];
    for (final f in foods) {
      final has = match.items.any(
        (i) => i.toLowerCase() == f.toLowerCase(),
      );
      if (!has) missing.add(f);
    }

    final pricesOnly = match.withItemPrices(prices);
    final pricesChanged =
        pricesOnly.itemPrices.length != match.itemPrices.length ||
            prices.entries.any(
              (e) => match.itemPrices[e.key] != e.value,
            );

    if (missing.isEmpty && !pricesChanged) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.updateBundleNothingNew)),
      );
      return;
    }

    if (missing.isNotEmpty) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          title: Text(
            t.updateBundleTitle(match.displayName(arabic: t.isAr)),
          ),
          content: Text(t.updateBundleBody(missing.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.updateBundleConfirm),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    final updated = pricesOnly.copyWith(
      items: missing.isEmpty ? match.items : [...match.items, ...missing],
    );
    final next = BundlesStore.replace(groups, updated);
    await BundlesStore.save(next, _prefs);
    if (!mounted) return;
    setState(() => _groups = next);
    AppHaptics.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.buildBundleUpdated)),
    );
  }

  RestaurantGroup? _findBundleByName(
    List<RestaurantGroup> groups,
    String name,
  ) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final g in groups) {
      if (g.id == RestaurantGroup.freeformId) continue;
      if (g.nameEn.toLowerCase() == key || g.nameAr.toLowerCase() == key) {
        return g;
      }
    }
    return null;
  }

  /// Bundle-button state for the current order.
  /// Returns null to hide the button (Mixed list, order already matches the
  /// bundle, or no new items were added), 'create' for “Create bundle”,
  /// 'update' for “Update bundle”.
  String? _bundleActionFor(OrderSession session) {
    final name = session.groupName?.trim() ?? '';
    final mixed =
        name == 'Mixed' || name == 'مختلط' || name == t.mixedBundleName.trim();
    if (mixed) return null;

    RestaurantGroup? match;
    final id = session.groupId;
    if (id != null && id.isNotEmpty && id != RestaurantGroup.freeformId) {
      for (final g in _groups) {
        if (g.id == id) {
          match = g;
          break;
        }
      }
    }
    if (match == null) return 'create';

    final ordered = OrderStore.foodTitlesFromSession(session)
        .map((f) => f.toLowerCase().trim())
        .toSet();
    final items = match.items
        .where(
            (i) => !AppValues.specialFoodKeys.contains(i.toLowerCase().trim()))
        .map((i) => i.toLowerCase().trim())
        .toSet();
    final added = ordered.difference(items);
    return added.isEmpty ? null : 'update';
  }

  /// Fast path for “Update list”: merge this order's foods + prices into the
  /// existing bundle without asking for a name.
  Future<void> _updateBundle(OrderSession session) async {
    final id = session.groupId;
    if (id == null || id.isEmpty || id == RestaurantGroup.freeformId) return;
    RestaurantGroup? match;
    for (final g in _groups) {
      if (g.id == id) {
        match = g;
        break;
      }
    }
    if (match == null) return;

    final foods = OrderStore.foodTitlesFromSession(session);
    final mergedItems = OrderStore.mergeFoods(match.items, foods);
    final prices = <String, double>{
      for (final f in foods)
        if (session.priceForTitle(f) > 0)
          f.toLowerCase(): session.priceForTitle(f),
    };
    var updated = match.copyWith(items: mergedItems);
    updated = updated.withItemPrices(prices);
    final next = BundlesStore.replace(_groups, updated);
    await BundlesStore.save(next, _prefs);
    if (!mounted) return;
    setState(() => _groups = next);
    AppHaptics.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.buildBundleUpdated)),
    );
  }

  Future<void> _finishOrder() async {
    if (_fromHistory) return;
    final current = _current;
    if (current == null || !current.hasContent) return;

    AppHaptics.mediumImpact();
    await _pushHistory(current);
    await OrderStore.saveCurrent(null, _prefs);
    await CrewStore.instance.pruneNonFavorites();
    setState(() => _current = null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.savedDone)),
    );
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      HomePage.route,
      (route) => false,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_neonUnlocked || _fromHistory) return false;
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      final delta = notification.scrollDelta ?? 0;
      if (delta < -5) {
        _swipeDownCount++;
        _swipeResetTimer?.cancel();
        _swipeResetTimer = Timer(const Duration(seconds: 10), () {
          _swipeDownCount = 0;
        });
        if (_swipeDownCount >= 5) {
          _unlockNeonTheme();
        } else {
          final remaining = 5 - _swipeDownCount;
          AppHaptics.lightImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '⚡ $remaining more swipe${remaining > 1 ? 's' : ''}...'),
                duration: const Duration(milliseconds: 800),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
    return false;
  }

  Future<void> _unlockNeonTheme() async {
    if (_unlocking) return;
    _unlocking = true;
    _neonUnlocked = true;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(AppValues.prefsNeonUnlocked, true);
    AppHaptics.heavyImpact();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    for (var i = 3; i >= 1; i--) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('⚡ Neon Theme in $i...'),
          duration: const Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    }

    await AppSettings.instance.setColorPalette(ColorPalette.neon);
    if (!mounted) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('🚀 Neon Theme activated! 🔥'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = t;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final pricesOn = AppSettings.instance.pricesEnabled;

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

        final current = _current;
        final hasCurrent = current != null && current.hasContent;

        return SummaryOnboarding(
          key: _summaryOnboardingKey,
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
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 18, 12, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Semantics(
                                      button: true,
                                      label: MaterialLocalizations.of(context)
                                          .backButtonTooltip,
                                      child: IconButton(
                                        onPressed: () =>
                                            Navigator.maybePop(context),
                                        icon: const Icon(
                                            Icons.arrow_back_rounded),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _fromHistory
                                            ? strings.pastOrderTitle
                                            : strings.summaryTitle,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_fromHistory)
                                  const WizardStepBar(currentStep: 3),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),
                                if (!hasCurrent)
                                  _EmptySummary(
                                    t: strings,
                                    onHome: () => Navigator.popUntil(
                                      context,
                                      (r) => r.isFirst,
                                    ),
                                  )
                                else ...[
                                  // ── 1) Whole order: item → units ──────────
                                  SectionCard(
                                    key: _wholeOrderKey,
                                    title: strings.orderItemsTitle,
                                    subtitle: strings.orderItemsSubtitle,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (current.hasPlace) ...[
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Chip(
                                              avatar: const Icon(
                                                Icons.storefront_rounded,
                                                size: 16,
                                              ),
                                              label: Text(current.groupName!),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                        if (current.aggregateFoods().isEmpty)
                                          Text(
                                            strings.emptyOrder,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          )
                                        else
                                          for (final a
                                              in current.aggregateFoods()) ...[
                                            // Form: [ 2  Eggs     14 ] — qty, name, total
                                            _OrderItemRow(
                                              title: strings.foodTitle(a.title),
                                              qtyLabel: '${a.qty}',
                                              showPrice: pricesOn,
                                              priceLabel: pricesOn
                                                  ? strings
                                                      .formatAmount(a.lineTotal)
                                                  : null,
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        if (pricesOn) ...[
                                          const Divider(height: 20),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '${strings.foodSubtotalLabel}: ${strings.money(current.orderTotal)}',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // ── 2) Who ordered what (saved order) ──────
                                  Builder(
                                    builder: (context) {
                                      // Only people who actually ordered something.
                                      final orderedPeople =
                                          current.peopleWithOrders;
                                      final showMoney = pricesOn;
                                      return SectionCard(
                                        key: _whoOrderedKey,
                                        title: strings.whoOrderedTitle,
                                        child: orderedPeople.isEmpty
                                            ? Text(
                                                strings.emptyOrder,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  for (final (i, p)
                                                      in orderedPeople
                                                          .indexed) ...[
                                                    _PersonBlock(
                                                      person: p,
                                                      index: i,
                                                      lines: current
                                                          .linesFor(p.id),
                                                      emptyLabel:
                                                          strings.emptyOrder,
                                                      showPrices: pricesOn,
                                                      extrasShare: pricesOn
                                                          ? current
                                                              .personExtrasShareFor(
                                                              p.id,
                                                              mode: _splitMode(
                                                                pricesOn,
                                                              ),
                                                              round:
                                                                  _roundTotals(
                                                                pricesOn,
                                                              ),
                                                            )
                                                          : 0,
                                                      totalLabel: showMoney
                                                          ? strings
                                                              .personTotalLabel(
                                                              current
                                                                  .personGrandTotalFor(
                                                                p.id,
                                                                mode:
                                                                    _splitMode(
                                                                  pricesOn,
                                                                ),
                                                                round:
                                                                    _roundTotals(
                                                                  pricesOn,
                                                                ),
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],
                                                ],
                                              ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Actions
                                  Column(
                                    key: _actionsKey,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed: () => _share(current),
                                              icon: const Icon(
                                                  Icons.ios_share_rounded),
                                              label: Text(strings.shareSummary),
                                            ),
                                          ),
                                          if (_bundleActionFor(current)
                                              case final action?) ...[
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: () =>
                                                    action == 'update'
                                                        ? _updateBundle(current)
                                                        : _buildBundle(current),
                                                icon: Icon(
                                                  action == 'update'
                                                      ? Icons.update_rounded
                                                      : Icons
                                                          .playlist_add_rounded,
                                                  size: 20,
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
                                      const SizedBox(height: 10),
                                      if (_fromHistory)
                                        FilledButton.tonalIcon(
                                          onPressed: () => _orderAgain(current),
                                          icon:
                                              const Icon(Icons.replay_rounded),
                                          label: Text(strings.orderAgainCta),
                                        )
                                      else
                                        FilledButton.tonalIcon(
                                          onPressed: _finishOrder,
                                          icon: const Icon(
                                              Icons.check_circle_outline),
                                          label: Text(strings.finishOrder),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Whole-order line: `2  Eggs     14` — amount, space, name [, total if Prices].
class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.title,
    required this.qtyLabel,
    required this.showPrice,
    this.priceLabel,
  });

  final String title;
  final String qtyLabel;
  final bool showPrice;
  final String? priceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final qtyStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    final nameStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final priceStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.primary,
    );

    return Semantics(
      label: showPrice && priceLabel != null
          ? '$qtyLabel $title $priceLabel'
          : '$qtyLabel $title',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(qtyLabel, style: qtyStyle),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nameStyle,
              ),
            ),
            if (showPrice) ...[
              const SizedBox(width: 12),
              Text(
                priceLabel ?? '0',
                style: priceStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptySummary extends StatelessWidget {
  const _EmptySummary({required this.t, required this.onHome});

  final Translate t;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.12),
            scheme.surface.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
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
              Icons.receipt_long_rounded,
              size: 36,
              color: scheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noActiveOrder,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onHome, child: Text(t.goHome)),
        ],
      ),
    );
  }
}

class _PersonBlock extends StatelessWidget {
  const _PersonBlock({
    required this.person,
    required this.index,
    required this.lines,
    required this.emptyLabel,
    this.showPrices = false,
    this.totalLabel,
    this.extrasShare = 0,
  });

  final Person person;
  final int index;
  final List<OrderLine> lines;
  final String emptyLabel;
  final bool showPrices;
  final String? totalLabel;

  /// Share of tip + delivery for this person (0 when none).
  final double extrasShare;

  @override
  Widget build(BuildContext context) {
    final t = Translate.instance;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconStyle = AppSettings.instance.friendIconStyle;
    final mark = friendIconMark(person, iconStyle, index);
    final isEmoji = friendUsesEmoji(person, iconStyle);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: person.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: BorderDirectional(
          start: BorderSide(color: person.color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: person.color.withValues(alpha: 0.25),
                child: Text(
                  mark,
                  style: TextStyle(
                    fontSize: isEmoji ? 14 : 10,
                    fontWeight: FontWeight.w800,
                    color: isEmoji ? null : person.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(person.name, style: theme.textTheme.titleSmall),
              ),
              if (totalLabel != null)
                Text(
                  totalLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (lines.isEmpty)
            Text(
              emptyLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            ...lines.map((l) {
              final name = t.foodTitle(l.title);
              final note = l.note.isEmpty ? '' : ' — ${l.note}';
              // Same form as Whole order: `2  Eggs` [, price]
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      '${l.qty}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$name$note',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showPrices) ...[
                      const SizedBox(width: 8),
                      Text(
                        t.formatAmount(l.lineTotal),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          if (showPrices && extrasShare > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  t.extrasSectionTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.extrasShareHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  t.formatAmount(extrasShare),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
