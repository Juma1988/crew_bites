import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_haptics.dart';
import '../../core/theme.dart';
import '../../core/translate.dart';
import '../../core/values/app_values.dart';

/// In-page onboarding overlay for the "Who eats what" page.
/// Teaches Prices, Tip & delivery, Bundles, and Undo — only once.
class OrdersOnboarding extends StatefulWidget {
  const OrdersOnboarding({super.key, required this.child});

  final Widget child;

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppValues.prefsOrdersOnboardingDone) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppValues.prefsOrdersOnboardingDone, true);
  }

  @override
  State<OrdersOnboarding> createState() => OrdersOnboardingState();
}

class OrdersOnboardingState extends State<OrdersOnboarding> {
  static const t = Translate();
  OverlayEntry? _overlay;
  int _step = 0;
  bool _done = false;
  bool _waitingForFoodSelection = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final done = await OrdersOnboarding.isDone();
    if (done || !mounted) {
      if (mounted) setState(() => _done = true);
      return;
    }
    // Start onboarding after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startStep1();
    });
  }

  void _startStep1() {
    _step = 1;
    _showOverlay(
      icon: Icons.payments_rounded,
      title: t.obPricesTitle,
      body: t.obPricesBody,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _startStep2() {
    _step = 2;
    _showOverlay(
      icon: Icons.delivery_dining_rounded,
      title: t.obServicesTitle,
      body: t.obServicesBody,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _startStep3() {
    _step = 3;
    _showOverlay(
      icon: Icons.schedule_rounded,
      title: t.obBundlesTitle,
      body: t.obBundlesBody,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _startStep4() {
    _step = 4;
    _waitingForFoodSelection = true;
    // Don't show overlay yet — wait for first food assignment.
  }

  void _showUndoStep() {
    _waitingForFoodSelection = false;
    _step = 5;
    _showOverlay(
      icon: Icons.undo_rounded,
      title: t.obUndoTitle,
      body: t.obUndoBody,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _finish() async {
    _step = 6;
    await OrdersOnboarding.markDone();
    if (!mounted) return;
    _showOverlay(
      icon: Icons.check_circle_outline_rounded,
      title: t.onboardingDoneTitle,
      body: t.onboardingDoneBody,
      buttonText: t.onboardingDone,
      onTap: () {
        _overlay?.remove();
        _overlay = null;
        setState(() => _done = true);
      },
    );
  }

  void _next() {
    _overlay?.remove();
    _overlay = null;
    switch (_step) {
      case 1:
        _startStep2();
        break;
      case 2:
        _startStep3();
        break;
      case 3:
        _startStep4();
        break;
      case 5:
        _finish();
        break;
    }
  }

  /// Called by the parent when a food is assigned to a person.
  void onFoodAssigned() {
    if (_done || !_waitingForFoodSelection) return;
    _showUndoStep();
  }

  void _showOverlay({
    required IconData icon,
    required String title,
    required String body,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (ctx) => _OrdersOnboardingCard(
        icon: icon,
        title: title,
        body: body,
        buttonText: buttonText,
        onTap: onTap,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Floating card shown during orders onboarding.
class _OrdersOnboardingCard extends StatelessWidget {
  const _OrdersOnboardingCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Semi-transparent backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),
        // Card positioned in the upper-center area
        Positioned(
          top: topPadding + 80,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (context, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - val)),
                  child: child,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                      child: Icon(icon, size: 28, color: scheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          AppHaptics.selectionClick();
                          onTap();
                        },
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
