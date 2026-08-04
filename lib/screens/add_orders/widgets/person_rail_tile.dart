import 'package:flutter/material.dart';
import 'package:app_101/core/states/app_settings.dart';
import 'package:app_101/core/friend_icon_style.dart';
import 'package:app_101/models/order_models.dart';

class PersonRailTile extends StatelessWidget {
  const PersonRailTile({
    super.key,
    required this.person,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final Person person;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = person.color;
    final style = AppSettings.instance.friendIconStyle;
    final mark = friendIconMark(person, style, index);
    final isEmoji = friendUsesEmoji(person, style);

    return Material(
      color: selected
          ? color.withValues(alpha: 0.22)
          : scheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.3),
                child: Text(
                  mark,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isEmoji ? 14 : 10,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                person.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 9,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
