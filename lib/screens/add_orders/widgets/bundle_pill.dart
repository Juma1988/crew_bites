import 'package:flutter/material.dart';
import 'package:app_101/core/translate.dart';
import 'package:app_101/models/restaurant_group.dart';
import 'package:app_101/models/order_models.dart';

class BundlePill extends StatelessWidget {
  const BundlePill({
    super.key,
    required this.group,
    required this.label,
    required this.onTap,
    required this.onLongPress,
    this.selected = false,
  });

  final RestaurantGroup group;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = Color(group.colorValue);
    final t = Translate.instance;
    // Older/custom bundles may have the placeholder icon. Derive a stable
    // food emoji from the bundle id instead of changing it on every rebuild.
    final emoji = group.emoji.trim().isEmpty || group.emoji == '🍽️'
        ? PersonPalette.randomEmoji(_stableSeed(group.id))
        : group.emoji;

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '${t.activeBundleBadge}: $label' : label,
      hint: t.selectBundleHint,
      child: Material(
        color: color.withValues(alpha: selected ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    selected ? scheme.primary : color.withValues(alpha: 0.55),
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _stableSeed(String value) => value.codeUnits.fold(
        0,
        (sum, codeUnit) => (sum * 31 + codeUnit) & 0x7fffffff,
      );
}
