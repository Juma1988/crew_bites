import 'package:flutter/material.dart';
import 'package:app_101/core/translate.dart';
import 'package:app_101/models/restaurant_group.dart';

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
                color: selected ? scheme.primary : color.withValues(alpha: 0.55),
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                  color: selected ? scheme.primary : color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
