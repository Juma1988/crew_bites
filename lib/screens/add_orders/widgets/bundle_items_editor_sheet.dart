import 'package:flutter/material.dart';
import 'package:app_101/core/app_haptics.dart';
import 'package:app_101/core/translate.dart';
import 'package:app_101/core/values/app_values.dart';
import 'package:app_101/models/order_models.dart';
import 'package:app_101/models/restaurant_group.dart';

/// Bottom sheet: edit foods this bundle pushes into the food column.
class BundleItemsEditorSheet extends StatefulWidget {
  const BundleItemsEditorSheet({
    super.key,
    required this.t,
    required this.group,
    required this.onChanged,
    this.onDelete,
  });

  final Translate t;
  final RestaurantGroup group;
  final Future<void> Function(RestaurantGroup next) onChanged;
  final Future<void> Function()? onDelete;

  @override
  State<BundleItemsEditorSheet> createState() =>
      _BundleItemsEditorSheetState();
}

class _BundleItemsEditorSheetState extends State<BundleItemsEditorSheet> {
  late List<String> _items;
  late String _emoji;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Translate get t => widget.t;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.group.items);
    _emoji = widget.group.emoji;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _commit(List<String> items) async {
    setState(() => _items = items);
    await widget.onChanged(widget.group.copyWith(items: List<String>.from(items)));
  }

  Future<void> _addItem() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    if (_items.any((f) => f.toLowerCase() == name.toLowerCase())) {
      _controller.clear();
      _focusNode.requestFocus();
      return;
    }
    AppHaptics.selectionClick();
    final next = [..._items, name];
    _controller.clear();
    _focusNode.requestFocus();
    await _commit(next);
  }

  Future<void> _removeAt(int index) async {
    // Special items (Tip, Delivery) can't be removed from bundles.
    if (AppValues.specialFoodKeys.contains(_items[index].toLowerCase().trim())) {
      return;
    }
    AppHaptics.lightImpact();
    final next = List<String>.from(_items)..removeAt(index);
    await _commit(next);
  }

  Future<void> _done() async {
    final name = _controller.text.trim();
    if (name.isNotEmpty &&
        !_items.any((f) => f.toLowerCase() == name.toLowerCase())) {
      await _commit([..._items, name]);
    }
    if (mounted) Navigator.pop(context);
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.personEmoji,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                  final isSelected = e == _emoji;
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selectionClick();
                      setState(() => _emoji = e);
                      Navigator.pop(ctx);
                      widget.onChanged(
                        widget.group.copyWith(emoji: e),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final title = t.editBundleTitle(
      widget.group.displayName(arabic: t.isAr),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _showEmojiPicker,
                    child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          t.editBundleHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                ),
                child: _items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          t.bundleItemEmpty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        separatorBuilder: (a, b) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          return Material(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                _items[i],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: t.delete,
                                onPressed: () => _removeAt(i),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: scheme.error,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLength: AppValues.maxNameLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: t.foodName,
                        hintText: t.foodNameHint,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addItem,
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.onDelete != null)
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: Text(t.deleteBundle),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: Text(t.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: Text(t.delete),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await widget.onDelete!();
                      },
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      label: Text(
                        t.deleteBundle,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _done,
                    child: Text(t.done),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
