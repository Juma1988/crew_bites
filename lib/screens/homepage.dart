import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_haptics.dart';
import '../core/debug/debug_registry.dart';
import '../core/friend_icon_style.dart';
import '../core/states/app_settings.dart';
import '../core/states/order_store.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';
import '../models/order_models.dart';
import '../widgets/food_crew_illustration.dart';
import 'add_orders_page.dart';
import 'add_user_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

/// Home — polished entry for Crew Bites group food orders.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const route = '/';

  /// Debug overlay reads this to show + copy the file owning the page.
  static const String debugSourceFile = 'lib/screens/homepage.dart';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  SharedPreferences? _prefs;
  OrderSession? _current;
  bool _ready = false;

  late final AnimationController _enter;
  late final CurvedAnimation _enterCurve;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const t = Translate();

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _enterCurve = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _fade = _enterCurve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_enterCurve);
    _load();
  }

  @override
  void dispose() {
    _enterCurve.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _load({bool animate = true}) async {
    final prefs = await SharedPreferences.getInstance();
    void onCorrupt() => AppSettings.instance.notePrefsCorrupt();
    final current = await OrderStore.loadCurrent(prefs, onCorrupt);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _current = current;
      _ready = true;
    });
    if (AppSettings.instance.prefsLoadWarning && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.prefsCorruptToast)),
      );
      AppSettings.instance.clearPrefsWarning();
    }
    if (!animate || !mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _enter.value = 1;
    } else if (_enter.status != AnimationStatus.completed) {
      _enter.forward();
    }
  }

  Future<void> _openRoute(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) await _load(animate: false);
  }

  /// Resume last order. When the crew already exists, stack is
  /// Home → People → Food so Back from food returns to add/remove people
  /// (not straight Home).
  Future<void> _continueLastOrder() async {
    AppHaptics.lightImpact();
    final current = _current;
    if (current != null && current.people.isNotEmpty) {
      final nav = Navigator.of(context);
      final peopleFuture = nav.pushNamed(AddUserPage.route);
      await nav.pushNamed(AddOrdersPage.route);
      await peopleFuture;
      if (mounted) await _load(animate: false);
    } else {
      await _openRoute(AddUserPage.route);
    }
  }

  Future<void> _startNewOrder() async {
    AppHaptics.mediumImpact();
    await OrderStore.startNewOrder(_prefs);
    setState(() {
      _current = null;
    });
    await _openRoute(AddUserPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final strings = t;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (DebugRegistry.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugRegistry.currentFile.value = 'lib/screens/homepage.dart';
      });
    }

    if (!_ready) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppTheme.brandName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 28,
                height: 28,
                child: Semantics(
                  label: 'Loading',
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final current = _current;
    final hasCurrent = current != null && current.hasContent;

    // LTR comes from MaterialApp builder in main.dart.
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient(scheme),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: _Blob(
              size: 180,
              color: scheme.primary.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.10
                    : 0.16,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: _Blob(
              size: 140,
              color: scheme.tertiary.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.08
                    : 0.12,
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: _TopBar(),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 18),
                            Text(
                              strings.homeGreeting,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strings.homeHeadline,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 42,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (hasCurrent)
                              _ActiveOrderCard(
                                t: strings,
                                session: current,
                                onContinue: _continueLastOrder,
                                onNew: _startNewOrder,
                              )
                            else
                              _EmptyHero(
                                t: strings,
                                onStart: _startNewOrder,
                              ),
                            const SizedBox(height: 28),
                            _HomeNavTile(
                              icon: Icons.history_rounded,
                              label: strings.historyPeekTitle,
                              onTap: () {
                                AppHaptics.selectionClick();
                                _openRoute(HistoryPage.route);
                              },
                            ),
                            const SizedBox(height: 12),
                            _HomeNavTile(
                              icon: Icons.settings_outlined,
                              label: strings.settingsTitle,
                              onTap: () {
                                AppHaptics.selectionClick();
                                _openRoute(SettingsPage.route);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ── UI pieces ─────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                AppTheme.brandName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home list row → History or Settings.
class _HomeNavTile extends StatelessWidget {
  const _HomeNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppValues.minTouch),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({
    required this.t,
    required this.onStart,
  });

  final Translate t;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.15),
            scheme.surface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: AppTheme.softShadow(theme.brightness),
      ),
      child: Column(
        children: [
          const FoodCrewIllustration(size: 280),
          const SizedBox(height: 4),
          Text(
            t.homeEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            t.homeEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 56,
              maxWidth: double.infinity,
            ),
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.group_add_rounded, size: 26),
              label: Text(
                t.startFreshCta,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.t,
    required this.session,
    required this.onContinue,
    required this.onNew,
  });

  final Translate t;
  final OrderSession session;
  final VoidCallback onContinue;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.75),
            scheme.tertiary,
          ],
        ),
        boxShadow: AppTheme.softShadow(theme.brightness),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard - 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        t.activeOrderBadge,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  t.peopleItemsSummary(
                    session.people.length,
                    session.itemCount,
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(t.welcomeBackTitle, style: theme.textTheme.titleLarge),
            if (session.hasPlace) ...[
              const SizedBox(height: 6),
              Text(
                session.groupName!,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: Stack(
                children: [
                  for (var i = 0; i < session.people.length && i < 5; i++)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      start: i * 30.0,
                      child: _PersonAvatar(
                        person: session.people[i],
                        index: i,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              session.people.map((p) => p.name).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: FilledButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.refresh_rounded, size: 26),
                label: Text(
                  t.startFreshCta,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: OutlinedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow_rounded, size: 26),
                label: Text(
                  t.resumeCta,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.person, required this.index});

  final Person person;
  final int index;

  @override
  Widget build(BuildContext context) {
    final style = AppSettings.instance.friendIconStyle;
    final mark = friendIconMark(person, style, index);
    final isEmoji = friendUsesEmoji(person, style);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: person.color.withValues(alpha: 0.25),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        mark,
        style: TextStyle(
          fontSize: isEmoji ? 22 : 13,
          fontWeight: FontWeight.w800,
          color: isEmoji ? null : person.color,
          height: 1,
        ),
      ),
    );
  }
}
