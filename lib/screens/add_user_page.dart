import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../core/app_haptics.dart';
import '../core/friend_icon_style.dart';
import '../core/motion.dart';
import '../core/states/app_settings.dart';
import '../core/states/crew_store.dart';
import '../core/states/order_store.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';
import '../models/order_models.dart';
import '../support/dialog/add_users_dialog.dart';
import '../widgets/onboarding_overlay.dart';
import '../widgets/wizard_step_bar.dart';
import 'add_orders_page.dart';

/// Select people for this order. State lives in [CrewStore] (core/states).
class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  static const route = AppValues.routeAddUser;

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  static const t = Translate();
  final _crew = CrewStore.instance;
  final _listKey = GlobalKey();
  final _addKey = GlobalKey();
  final _nextKey = GlobalKey();
  final _onboardingKey = GlobalKey<OnboardingOverlayState>();

  @override
  void initState() {
    super.initState();
    _crew.load();
  }

  Future<void> _openAddDialog() async {
    AppHaptics.selectionClick();
    final result = await AddUsersDialog.show(
      context,
      t: t,
      existingNames: _crew.names,
    );
    if (result == null || !mounted) return;
    if (!_crew.canAddToRoster) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.maxCrewRosterReached(AppValues.maxCrewRoster),
          ),
        ),
      );
      return;
    }
    final ok = await _crew.addPerson(
      name: result.name,
      colorValue: result.colorValue,
      emoji: result.emoji,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.maxCrewRosterReached(AppValues.maxCrewRoster),
          ),
        ),
      );
    }
    if (ok && mounted) {
      _onboardingKey.currentState?.onPersonAdded(_crew.names.length);
    }
  }

  Future<void> _onLongPress(String name, int index) async {
    AppHaptics.mediumImpact();
    final strings = t;
    final color = Color(_crew.colorFor(name, index));
    final emoji = _crew.emojiFor(name);
    final iconStyle = AppSettings.instance.friendIconStyle;
    final markPerson = Person(
      id: name,
      name: name,
      emoji: emoji,
      colorValue: color.toARGB32(),
    );
    final mark = friendIconMark(markPerson, iconStyle, index);
    final markIsEmoji = friendUsesEmoji(markPerson, iconStyle);

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.28),
                  child: Text(
                    mark,
                    style: TextStyle(
                      fontSize: markIsEmoji ? 22 : 14,
                      fontWeight: FontWeight.w800,
                      color: markIsEmoji ? null : color,
                    ),
                  ),
                ),
                title: Text(name, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(strings.renamePerson),
                onTap: () => Navigator.pop(ctx, 'rename'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  strings.delete,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'rename') await _rename(name);
    if (action == 'delete') await _deleteCustom(name);
  }

  Future<void> _rename(String oldName) async {
    final result = await AddUsersDialog.show(
      context,
      t: t,
      existingNames: _crew.names.where((n) => n != oldName).toList(),
      initialName: oldName,
      initialColor: _crew.colorFor(oldName, _crew.names.indexOf(oldName)),
      initialEmoji: _crew.emojiFor(oldName),
      isRename: true,
    );
    if (result == null || !mounted) return;
    await _crew.renamePerson(
      oldName: oldName,
      newName: result.name,
      colorValue: result.colorValue,
      emoji: result.emoji,
    );
    // Keep active order people names in sync (M2).
    final current = await OrderStore.loadCurrent();
    if (current != null) {
      final people = [
        for (final p in current.people)
          if (p.name.toLowerCase() == oldName.toLowerCase())
            p.copyWith(
              name: result.name,
              colorValue: result.colorValue,
              emoji: result.emoji,
            )
          else
            p,
      ];
      await OrderStore.saveCurrent(current.copyWith(people: people));
    }
  }

  Future<void> _deleteCustom(String name) async {
    // Menu delete still asks once — then Undo snackbar.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deletePersonConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _removePersonWithUndo(name);
  }

  /// Swipe delete: no dialog (fast) + Undo snackbar = safer than confirm only.
  Future<bool> _confirmSwipeDelete(String name) async {
    await _removePersonWithUndo(name);
    return true;
  }

  /// Snapshot → remove → SnackBar with Undo to restore name/emoji/color/fav.
  Future<void> _removePersonWithUndo(String name) async {
    final color = _crew.colorFor(name, _crew.names.indexOf(name));
    final emoji = _crew.emojiFor(name);
    final wasSelected = _crew.selected.contains(name);
    final wasFavorite = _crew.isFavorite(name);

    final removed = await _crew.deletePerson(name);
    if (!removed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.personRemovedToast(name)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: t.undo,
          onPressed: () async {
            await _crew.restorePerson(
              name: name,
              colorValue: color,
              emoji: emoji,
              wasSelected: wasSelected,
              wasFavorite: wasFavorite,
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(String name) async {
    AppHaptics.selectionClick();
    final wasFav = _crew.isFavorite(name);
    await _crew.toggleFavorite(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFav ? t.removedFromFavorites : t.addedToFavorites,
        ),
        duration: AppValues.snackTiny,
      ),
    );
  }

  void _toggle(String name) {
    AppHaptics.selectionClick();
    final ok = _crew.toggleSelect(name);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.maxCrewSelectedReached(AppValues.maxCrewSelected),
          ),
        ),
      );
    }
  }

  Future<void> _continue() async {
    final strings = t;
    if (_crew.selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.selectAtLeastOne)),
      );
      return;
    }

    AppHaptics.mediumImpact();
    final existing = await OrderStore.loadCurrent();
    final people = _crew.buildSelectedPeople(existing);

    final keepIds = people.map((p) => p.id).toSet();
    final nameToId = {for (final p in people) p.name: p.id};
    final idToName = {
      for (final p in existing?.people ?? const <Person>[]) p.id: p.name,
    };
    final lines = <OrderLine>[];
    for (final line in existing?.lines ?? const <OrderLine>[]) {
      final ownerName = idToName[line.personId];
      if (ownerName == null) continue;
      final newId = nameToId[ownerName];
      if (newId == null || !keepIds.contains(newId)) continue;
      lines.add(line.copyWith(personId: newId));
    }

    final session = OrderSession(
      id: existing?.id ?? 's_${DateTime.now().microsecondsSinceEpoch}',
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      people: people,
      lines: lines,
      groupId: existing?.groupId,
      groupName: existing?.groupName,
      // Keep menu unit prices when revisiting People → Next (C2).
      foodPrices: Map<String, double>.from(existing?.foodPrices ?? const {}),
    );

    await OrderStore.saveCurrent(session);
    if (!mounted) return;
    Navigator.pushNamed(context, AddOrdersPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final strings = t;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _crew,
      builder: (context, _) {
        if (!_crew.ready) {
          return Scaffold(
            body: Center(
              child: Semantics(
                label: 'Loading',
                child: const CircularProgressIndicator(),
              ),
            ),
          );
        }

        final names = _crew.names;

        return OnboardingOverlay(
          key: _onboardingKey,
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
                      padding: const EdgeInsets.fromLTRB(8, 12, 12, 0),
                      child: Row(
                        children: [
                          Semantics(
                            button: true,
                            label: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            child: IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              strings.pickCrewTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppValues.radiusPill,
                              ),
                            ),
                            child: Text(
                              '${strings.selectedCount} ${_crew.selected.length}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: WizardStepBar(currentStep: 1),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: KeyedSubtree(
                        key: _listKey,
                        child: names.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: scheme.primaryContainer.withValues(alpha: 0.3),
                                          border: Border.all(
                                            color: scheme.primary.withValues(alpha: 0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.group_add_rounded,
                                          size: 40,
                                          color: scheme.primary.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        strings.noPeopleYet,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        strings.noPeopleHint,
                                        textAlign: TextAlign.center,
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                        itemCount: names.length,
                        separatorBuilder: (a, b) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final name = names[index];
                          final selected = _crew.selected.contains(name);
                          final color = Color(_crew.colorFor(name, index));
                          final emoji = _crew.emojiFor(name);
                          final isFav = _crew.isFavorite(name);
                          final radius =
                              BorderRadius.circular(AppTheme.radiusCard);
                          final iconStyle =
                              AppSettings.instance.friendIconStyle;
                          final markPerson = Person(
                            id: name,
                            name: name,
                            emoji: emoji,
                            colorValue: color.toARGB32(),
                          );
                          final mark = friendIconMark(
                            markPerson,
                            iconStyle,
                            index,
                          );
                          final markIsEmoji =
                              friendUsesEmoji(markPerson, iconStyle);

                          return _ShortSwipeTile(
                            key: ValueKey('name_$name'),
                            borderRadius: radius,
                            favColor: scheme.tertiaryContainer,
                            favIconColor: scheme.onTertiaryContainer,
                            favIcon: isFav
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            // Clear red delete affordance (not soft errorContainer).
                            deleteColor: const Color(0xFFE53935),
                            deleteIconColor: Colors.white,
                            onFavorite: () => _toggleFavorite(name),
                            onDelete: () => _confirmSwipeDelete(name),
                            child: Material(
                              color: selected
                                  ? scheme.primaryContainer
                                      .withValues(alpha: 0.55)
                                  : scheme.surface.withValues(alpha: 0.92),
                              borderRadius: radius,
                              child: InkWell(
                                borderRadius: radius,
                                onTap: () => _toggle(name),
                                onLongPress: () => _onLongPress(name, index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: radius,
                                    border: Border.all(
                                      color: selected
                                          ? scheme.primary
                                          : scheme.outlineVariant
                                              .withValues(alpha: 0.5),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: AppValues.personAvatarRadius,
                                        backgroundColor:
                                            color.withValues(alpha: 0.28),
                                        child: Text(
                                          mark,
                                          style: TextStyle(
                                            fontSize: markIsEmoji ? 26 : 15,
                                            fontWeight: FontWeight.w800,
                                            color: markIsEmoji
                                                ? null
                                                : color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            if (isFav) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.star_rounded,
                                                size: 20,
                                                color: scheme.tertiary,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: AppValues.animNormal,
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? scheme.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? scheme.primary
                                                : scheme.outline,
                                            width: 2,
                                          ),
                                        ),
                                        child: selected
                                            ? Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                                color: scheme.onPrimary,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          // F21: add friend sits on the bottom bar (no FAB clash).
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: strings.addPerson,
                    child: FloatingActionButton(
                      key: _addKey,
                      heroTag: 'add_user_fab',
                      onPressed: _crew.canAddToRoster
                          ? _openAddDialog
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    strings.maxCrewRosterReached(
                                      AppValues.maxCrewRoster,
                                    ),
                                  ),
                                ),
                              );
                            },
                      tooltip: strings.addPerson,
                      child: const Icon(Icons.add_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      key: _nextKey,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _continue,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(strings.continueToOrders),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
        },
    );
  }
}

/// Name row short-swipe — UX polish:
/// short travel, spring snap, threshold haptics, RTL start/end, compact rails.
class _ShortSwipeTile extends StatefulWidget {
  const _ShortSwipeTile({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.favColor,
    required this.favIconColor,
    required this.favIcon,
    required this.deleteColor,
    required this.deleteIconColor,
    required this.onFavorite,
    required this.onDelete,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color favColor;
  final Color favIconColor;
  final IconData favIcon;
  final Color deleteColor;
  final Color deleteIconColor;
  final Future<void> Function() onFavorite;
  final Future<bool> Function() onDelete;

  /// Max card travel (px) — short, not full-width.
  static const double maxSlide = 58;

  /// Armed threshold (px).
  static const double actionAt = 36;

  /// Fixed action rail width (icon-only).
  static const double railW = 56;

  @override
  State<_ShortSwipeTile> createState() => _ShortSwipeTileState();
}

class _ShortSwipeTileState extends State<_ShortSwipeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snap;
  double _dx = 0;
  bool _busy = false;
  bool _armedFav = false;
  bool _armedDel = false;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _dx = _snap.value);
      });
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  /// +1 LTR, −1 RTL — maps physical dx so “toward start” opens favorite.
  double get _dirSign =>
      Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

  /// Logical offset: + = toward start (favorite), − = toward end (delete).
  double get _logical => _dx * _dirSign;

  void _onDragUpdate(DragUpdateDetails d) {
    if (_busy) return;
    _snap.stop();
    final next = (_dx + d.delta.dx).clamp(
      -_ShortSwipeTile.maxSlide,
      _ShortSwipeTile.maxSlide,
    );
    final logical = next * _dirSign;
    final fav = logical >= _ShortSwipeTile.actionAt;
    final del = logical <= -_ShortSwipeTile.actionAt;
    if (fav && !_armedFav) {
      HapticFeedback.selectionClick();
      _armedFav = true;
      _armedDel = false;
    } else if (del && !_armedDel) {
      HapticFeedback.selectionClick();
      _armedDel = true;
      _armedFav = false;
    } else if (!fav && !del) {
      _armedFav = false;
      _armedDel = false;
    }
    setState(() => _dx = next);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_busy) return;
    final logical = _logical;
    final velocity = details.primaryVelocity ?? 0;
    // Fling help: quick flick counts even slightly under threshold.
    final flingFav = velocity * _dirSign > 700 && logical > 16;
    final flingDel = velocity * _dirSign < -700 && logical < -16;

    if (logical >= _ShortSwipeTile.actionAt || flingFav) {
      await _fireFavorite();
      return;
    }
    if (logical <= -_ShortSwipeTile.actionAt || flingDel) {
      await _fireDelete();
      return;
    }
    _springTo(0);
  }

  void _springTo(double target) {
    final reduce = AppMotion.reduce(context);
    if (reduce) {
      setState(() {
        _dx = target;
        _armedFav = false;
        _armedDel = false;
      });
      return;
    }
    _snap.value = _dx;
    final sim = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 400, damping: 28),
      _dx,
      target,
      0,
    );
    _snap.animateWith(sim).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _armedFav = false;
        _armedDel = false;
      });
    });
  }

  Future<void> _fireFavorite() async {
    _busy = true;
    AppHaptics.selectionClick();
    _springTo(0);
    try {
      await widget.onFavorite();
    } finally {
      _busy = false;
      _armedFav = false;
      _armedDel = false;
    }
  }

  Future<void> _fireDelete() async {
    _busy = true;
    AppHaptics.mediumImpact();
    _springTo(0);
    try {
      await widget.onDelete();
    } finally {
      _busy = false;
      _armedFav = false;
      _armedDel = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translate.instance;
    final logical = _logical;
    final progress = (logical.abs() / _ShortSwipeTile.maxSlide).clamp(0.0, 1.0);
    final showFav = logical > 4;
    final showDel = logical < -4;
    final favScale = _armedFav ? 1.15 : 0.85 + 0.15 * progress;
    final delScale = _armedDel ? 1.15 : 0.85 + 0.15 * progress;

    // Physical sides: favorite under the edge the card slides away from.
    final favOnLeft = _dirSign > 0; // LTR: fav under left when card → right

    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: t.swipeFavorite): () {
          widget.onFavorite();
        },
        CustomSemanticsAction(label: t.swipeDelete): () {
          widget.onDelete();
        },
      },
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Compact action rails (not half-row color washes).
            Positioned.fill(
              child: Row(
                children: [
                  if (favOnLeft) ...[
                    _ActionRail(
                      width: _ShortSwipeTile.railW,
                      align: Alignment.center,
                      color: widget.favColor,
                      visible: showFav,
                      scale: favScale,
                      armed: _armedFav,
                      icon: widget.favIcon,
                      iconColor: widget.favIconColor,
                    ),
                    const Spacer(),
                    _ActionRail(
                      width: _ShortSwipeTile.railW,
                      align: Alignment.center,
                      color: widget.deleteColor,
                      visible: showDel,
                      scale: delScale,
                      armed: _armedDel,
                      icon: Icons.delete_outline_rounded,
                      iconColor: widget.deleteIconColor,
                    ),
                  ] else ...[
                    _ActionRail(
                      width: _ShortSwipeTile.railW,
                      align: Alignment.center,
                      color: widget.deleteColor,
                      visible: showDel,
                      scale: delScale,
                      armed: _armedDel,
                      icon: Icons.delete_outline_rounded,
                      iconColor: widget.deleteIconColor,
                    ),
                    const Spacer(),
                    _ActionRail(
                      width: _ShortSwipeTile.railW,
                      align: Alignment.center,
                      color: widget.favColor,
                      visible: showFav,
                      scale: favScale,
                      armed: _armedFav,
                      icon: widget.favIcon,
                      iconColor: widget.favIconColor,
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: () {
                if (!_busy) _springTo(0);
              },
              child: Transform.translate(
                offset: Offset(_dx, 0),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.width,
    required this.align,
    required this.color,
    required this.visible,
    required this.scale,
    required this.armed,
    required this.icon,
    required this.iconColor,
  });

  final double width;
  final Alignment align;
  final Color color;
  final bool visible;
  final double scale;
  final bool armed;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedOpacity(
        duration: AppMotion.of(context, AppValues.animFast),
        opacity: visible ? 1 : 0,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppValues.animFast),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: armed
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: align,
          child: Transform.scale(
            scale: scale,
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
      ),
    );
  }
}
