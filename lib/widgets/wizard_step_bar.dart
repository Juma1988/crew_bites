import 'package:flutter/material.dart';

import '../core/translate.dart';
import '../core/values/app_values.dart';

/// Compact step dots: Friends → Food → Summary.
class WizardStepBar extends StatelessWidget {
  const WizardStepBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  /// 1-based step index.
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final t = Translate.instance;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = [t.stepPeople, t.stepFood, t.stepSummary];

    return Semantics(
      label: t.wizardStepLabel(currentStep, totalSteps),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < totalSteps; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i < currentStep
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  _Dot(
                    active: i + 1 == currentStep,
                    done: i + 1 < currentStep,
                    index: i + 1,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              labels[(currentStep - 1).clamp(0, labels.length - 1)],
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.active,
    required this.done,
    required this.index,
  });

  final bool active;
  final bool done;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active || done ? scheme.primary : scheme.outlineVariant;
    return Container(
      width: AppValues.minTouchCompact * 0.55,
      height: AppValues.minTouchCompact * 0.55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? scheme.primary : color.withValues(alpha: 0.25),
        border: Border.all(color: color, width: 2),
      ),
      child: done && !active
          ? Icon(Icons.check_rounded, size: 14, color: scheme.primary)
          : Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
    );
  }
}
