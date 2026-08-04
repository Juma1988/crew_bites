import 'package:flutter/material.dart';
import 'package:app_101/core/theme.dart';

class AddFoodCard extends StatelessWidget {
  const AddFoodCard({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Same padding / border radius as [FoodTile] so heights match.
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.45),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
