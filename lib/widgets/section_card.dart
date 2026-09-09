import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Reusable card with title + optional icon + subtitle + child.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.borderColor,
    this.margin,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: borderColor ?? scheme.outline,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
