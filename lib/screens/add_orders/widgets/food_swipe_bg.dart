import 'package:flutter/material.dart';
import 'package:app_101/core/theme.dart';

class FoodSwipeBg extends StatelessWidget {
  const FoodSwipeBg({
    super.key,
    required this.label,
    required this.icon,
    required this.alignStart,
  });

  final String label;
  final IconData icon;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = [
      Icon(icon, color: scheme.onErrorContainer),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: scheme.onErrorContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    ];
    return Container(
      width: double.infinity,
      alignment: alignStart
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignStart ? row : row.reversed.toList(),
      ),
    );
  }
}
