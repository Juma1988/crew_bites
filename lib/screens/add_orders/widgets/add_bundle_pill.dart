import 'package:flutter/material.dart';

class AddBundlePill extends StatelessWidget {
  const AddBundlePill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Icon(Icons.add_rounded, size: 26, color: scheme.primary),
        ),
      ),
    );
  }
}
