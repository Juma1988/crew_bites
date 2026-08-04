import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_haptics.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';

/// In-page onboarding overlay that teaches swipe gestures step-by-step.
/// Shows only once (tracked via SharedPreferences).
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key, required this.child});

  final Widget child;

  /// Check if onboarding is already done.
  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppValues.prefsOnboardingDone) ?? false;
  }

  /// Mark onboarding as done.
  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppValues.prefsOnboardingDone, true);
  }

  @override
  State<OnboardingOverlay> createState() => OnboardingOverlayState();
}

class OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  static const t = Translate();
  OverlayEntry? _overlay;
  int _step = 0; // 0 = not started, 1-3 = steps, 4 = done
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final done = await OnboardingOverlay.isDone();
    if (done || !mounted) {
      if (mounted) setState(() => _done = true);
      return;
    }
    // Ready — will start when onPersonAdded is called.
  }

  void _startStep1() {
    _step = 1;
    _showOverlay(
      icon: Icons.waving_hand_rounded,
      title: t.onboardingStep1Title,
      body: t.onboardingStep1Body,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _startStep2() {
    _step = 2;
    _showOverlay(
      icon: Icons.star_rounded,
      title: t.onboardingStep2Title,
      body: t.onboardingStep2Body,
      buttonText: t.onboardingNext,
      onTap: _next,
      showSwipeDemo: true,
      swipeDirection: 'right',
    );
  }

  void _startStep3() {
    _step = 3;
    _showOverlay(
      icon: Icons.delete_outline_rounded,
      title: t.onboardingStep3Title,
      body: t.onboardingStep3Body,
      buttonText: t.onboardingNext,
      onTap: _next,
      showSwipeDemo: true,
      swipeDirection: 'left',
    );
  }

  void _finish() async {
    _step = 4;
    await OnboardingOverlay.markDone();
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
        _finish();
        break;
    }
  }

  /// Called by the parent after each person is added.
  void onPersonAdded(int totalCount) {
    if (_done) return;
    if (totalCount == 1 && _step == 0) {
      _startStep1();
    }
  }

  void _showOverlay({
    required IconData icon,
    required String title,
    required String body,
    required String buttonText,
    required VoidCallback onTap,
    bool showSwipeDemo = false,
    String swipeDirection = 'right',
  }) {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (ctx) => _OnboardingCard(
        icon: icon,
        title: title,
        body: body,
        buttonText: buttonText,
        onTap: onTap,
        showSwipeDemo: showSwipeDemo,
        swipeDirection: swipeDirection,
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

/// The floating card shown during onboarding.
class _OnboardingCard extends StatefulWidget {
  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonText,
    required this.onTap,
    this.showSwipeDemo = false,
    this.swipeDirection = 'right',
  });

  final IconData icon;
  final String title;
  final String body;
  final String buttonText;
  final VoidCallback onTap;
  final bool showSwipeDemo;
  final String swipeDirection;

  @override
  State<_OnboardingCard> createState() => _OnboardingCardState();
}

class _OnboardingCardState extends State<_OnboardingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeAnim;
  late final Animation<double> _swipeOffset;

  @override
  void initState() {
    super.initState();
    _swipeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final begin = widget.swipeDirection == 'right' ? -40.0 : 40.0;
    _swipeOffset = Tween<double>(begin: 0, end: begin).animate(
      CurvedAnimation(parent: _swipeAnim, curve: Curves.easeInOut),
    );
    if (widget.showSwipeDemo) {
      _swipeAnim.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _swipeAnim.dispose();
    super.dispose();
  }

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
            onTap: widget.onTap,
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
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                      child: Icon(widget.icon, size: 28, color: scheme.primary),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Body
                    Text(
                      widget.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Swipe demo animation
                    if (widget.showSwipeDemo) ...[
                      const SizedBox(height: 16),
                      _SwipeDemo(
                        animation: _swipeOffset,
                        direction: widget.swipeDirection,
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          AppHaptics.selectionClick();
                          widget.onTap();
                        },
                        child: Text(widget.buttonText),
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

/// Animated swipe demo showing a miniature tile sliding.
class _SwipeDemo extends StatelessWidget {
  const _SwipeDemo({
    required this.animation,
    required this.direction,
  });

  final Animation<double> animation;
  final String direction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRight = direction == 'right';

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Action rail peek
              Positioned(
                left: isRight ? 0 : null,
                right: isRight ? null : 0,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isRight
                        ? scheme.tertiaryContainer
                        : const Color(0xFFE53935),
                    borderRadius: BorderRadius.only(
                      topLeft: isRight ? const Radius.circular(14) : Radius.zero,
                      bottomLeft: isRight ? const Radius.circular(14) : Radius.zero,
                      topRight: isRight ? Radius.zero : const Radius.circular(14),
                      bottomRight: isRight ? Radius.zero : const Radius.circular(14),
                    ),
                  ),
                  child: Icon(
                    isRight ? Icons.star_rounded : Icons.delete_outline_rounded,
                    color: isRight
                        ? scheme.onTertiaryContainer
                        : Colors.white,
                    size: 22,
                  ),
                ),
              ),
              // Sliding tile
              Transform.translate(
                offset: Offset(animation.value, 0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          '🙂',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Swipe me!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
