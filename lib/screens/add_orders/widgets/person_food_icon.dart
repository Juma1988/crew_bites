import 'package:flutter/material.dart';
import 'package:app_101/core/states/app_settings.dart';
import 'package:app_101/core/friend_icon_style.dart';
import 'package:app_101/models/order_models.dart';

/// Compact person mark on a food row — emoji/initials; qty = repeated icons.
class PersonFoodIcon extends StatelessWidget {
  const PersonFoodIcon({
    super.key,
    required this.person,
    required this.index,
    required this.highlighted,
  });

  final Person person;
  final int index;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = person.color;
    final scheme = Theme.of(context).colorScheme;
    final style = AppSettings.instance.friendIconStyle;
    final mark = friendIconMark(person, style, index);
    final isEmoji = friendUsesEmoji(person, style);

    return Semantics(
      label: person.name,
      child: Tooltip(
        message: person.name,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: highlighted ? 0.32 : 0.18),
            border: Border.all(
              color: highlighted ? color : color.withValues(alpha: 0.5),
              width: highlighted ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            mark,
            style: TextStyle(
              fontSize: isEmoji ? 14 : 10,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
