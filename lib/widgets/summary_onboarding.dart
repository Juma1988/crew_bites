import 'package:flutter/material.dart';
import '../core/app_haptics.dart';
import '../core/services/shared_preferences_service.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';

/// In-page onboarding overlay for the Summary/Output page.
/// Teaches order review, sharing, and bundle saving — only once.
class SummaryOnboarding extends StatefulWidget {
  const SummaryOnboarding({super.key, required this.child});

  final Widget child;

  static Future<bool> isDone() async {
    final prefs = await SharedPreferencesService.instance.get();
    return prefs.getBool(AppValues.prefsSummaryOnboardingDone) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferencesService.instance.get();
    await prefs.setBool(AppValues.prefsSummaryOnboardingDone, true);
  }

  @override
  State<SummaryOnboarding> createState() => SummaryOnboardingState();
}

class SummaryOnboardingState extends State<SummaryOnboarding> {
  static const t = Translate();
  OverlayEntry? _overlay;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final done = await SummaryOnboarding.isDone();
    if (done || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startStep1();
    });
  }

  void _startStep1() {
    _step = 1;
    _showOverlay(
      icon: Icons.receipt_long_rounded,
      title: t.obSummaryTitle,
      body: t.obSummaryBody,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _startStep2() {
    _step = 2;
    _showOverlay(
      icon: Icons.ios_share_rounded,
      title: t.obShareTitle,
      body: t.obShareBody,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _startStep3() {
    _step = 3;
    _showOverlay(
      icon: Icons.playlist_add_rounded,
      title: t.obBundleSaveTitle,
      body: t.obBundleSaveBody,
      buttonText: t.onboardingNext,
      onTap: _next,
    );
  }

  void _finish() async {
    await SummaryOnboarding.markDone();
    if (!mounted) return;
    _showOverlay(
      icon: Icons.check_circle_outline_rounded,
      title: t.onboardingDoneTitle,
      body: t.onboardingDoneBody,
      buttonText: t.onboardingDone,
      onTap: () {
        _overlay?.remove();
        _overlay = null;
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

  void _showOverlay({
    required IconData icon,
    required String title,
    required String body,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (ctx) => _SummaryOnboardingCard(
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

class _SummaryOnboardingCard extends StatelessWidget {
  const _SummaryOnboardingCard({
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
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),
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
