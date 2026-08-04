import 'package:flutter/material.dart';

import '../../core/app_haptics.dart';
import '../../core/friend_icon_style.dart';
import '../../core/states/app_settings.dart';
import '../../core/theme.dart';
import '../../core/translate.dart';
import '../../models/order_models.dart';

/// Result of add / rename character dialog.
class AddUserResult {
  const AddUserResult({
    required this.name,
    required this.colorValue,
    required this.emoji,
  });

  final String name;
  final int colorValue;
  final String emoji;
}

/// Dialog: type name; emoji + color are random (funny face, not letters).
class AddUsersDialog extends StatefulWidget {
  const AddUsersDialog({
    super.key,
    required this.t,
    this.existingNames = const [],
    this.initialName,
    this.initialColor,
    this.initialEmoji,
    this.isRename = false,
  });

  final Translate t;
  final List<String> existingNames;
  final String? initialName;
  final int? initialColor;
  final String? initialEmoji;
  final bool isRename;

  static Future<AddUserResult?> show(
    BuildContext context, {
    required Translate t,
    List<String> existingNames = const [],
    String? initialName,
    int? initialColor,
    String? initialEmoji,
    bool isRename = false,
  }) {
    return showDialog<AddUserResult>(
      context: context,
      builder: (ctx) => AddUsersDialog(
        t: t,
        existingNames: existingNames,
        initialName: initialName,
        initialColor: initialColor,
        initialEmoji: initialEmoji,
        isRename: isRename,
      ),
    );
  }

  @override
  State<AddUsersDialog> createState() => _AddUsersDialogState();
}

class _AddUsersDialogState extends State<AddUsersDialog> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  late int _color;
  late String _emoji;
  String? _error;

  Translate get t => widget.t;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    if (widget.initialColor != null && widget.initialEmoji != null) {
      _color = widget.initialColor!;
      _emoji = widget.initialEmoji!;
    } else {
      final look = PersonPalette.randomLook();
      _color = widget.initialColor ?? look.color;
      _emoji = widget.initialEmoji ?? look.emoji;
    }
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _shuffleLook() {
    AppHaptics.selectionClick();
    final look = PersonPalette.randomLook();
    setState(() {
      _color = look.color;
      _emoji = look.emoji;
    });
  }

  void _selectEmoji(String emoji) {
    AppHaptics.selectionClick();
    setState(() => _emoji = emoji);
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EmojiPickerSheet(
        selected: _emoji,
        onSelect: (emoji) {
          Navigator.pop(ctx);
          _selectEmoji(emoji);
        },
        onRandom: () {
          Navigator.pop(ctx);
          _shuffleLook();
        },
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.nameRequired);
      return;
    }
    final exists = widget.existingNames.any(
      (n) =>
          n.toLowerCase() == name.toLowerCase() &&
          n.toLowerCase() != (widget.initialName ?? '').toLowerCase(),
    );
    if (exists) {
      setState(() => _error = t.nameAlreadyExists);
      return;
    }
    AppHaptics.lightImpact();
    Navigator.pop(
      context,
      AddUserResult(
        name: name,
        colorValue: _color,
        emoji: _emoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      title: Text(widget.isRename ? t.renamePerson : t.addPersonTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.addPersonHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: AppSettings.instance.friendIconStyle == FriendIconStyle.emoji
                  ? GestureDetector(
                      onTap: _showEmojiPicker,
                      child: Column(
                        children: [
                          _AvatarPreview(
                            name: _controller.text,
                            color: _color,
                            emoji: _emoji,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.tapToChangeAvatar,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _AvatarPreview(
                      name: _controller.text,
                      color: _color,
                      emoji: _emoji,
                    ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              decoration: InputDecoration(
                labelText: t.personName,
                hintText: t.personNameHint,
                errorText: _error,
                counterText: '',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Text(t.personColor, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in PersonPalette.colors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: c == _color
                              ? scheme.onSurface
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(t.save),
        ),
      ],
    );
  }
}

/// Shows the avatar preview respecting current [FriendIconStyle].
class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.name,
    required this.color,
    required this.emoji,
  });

  final String name;
  final int color;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final style = AppSettings.instance.friendIconStyle;
    final person = Person(
      id: '',
      name: name.isEmpty ? '?' : name,
      emoji: emoji,
      colorValue: color,
    );
    final mark = friendIconMark(person, style, 0);
    final isEmoji = friendUsesEmoji(person, style);

    return CircleAvatar(
      radius: 40,
      backgroundColor: Color(color).withValues(alpha: 0.28),
      child: Text(
        mark,
        style: TextStyle(
          fontSize: isEmoji ? 36 : 20,
          fontWeight: isEmoji ? null : FontWeight.w800,
          color: isEmoji ? null : Color(color),
        ),
      ),
    );
  }
}

/// Bottom sheet with emoji grid picker.
class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({
    required this.selected,
    required this.onSelect,
    required this.onRandom,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  Translate().personEmoji,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onRandom,
                  icon: const Icon(Icons.casino_outlined, size: 20),
                  label: Text(Translate().shuffleAvatarHint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: PersonPalette.emojis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final e = PersonPalette.emojis[index];
                final isSelected = e == selected;
                return GestureDetector(
                  onTap: () => onSelect(e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? scheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
