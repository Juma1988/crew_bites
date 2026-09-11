import 'package:flutter/material.dart';
import 'package:app_101/core/app_haptics.dart';
import 'package:app_101/core/translate.dart';
import 'package:app_101/core/values/app_values.dart';
import 'package:app_101/core/theme.dart';
import 'package:app_101/models/order_models.dart';
import 'person_food_icon.dart';

class FoodTile extends StatefulWidget {
  const FoodTile({
    super.key,
    required this.title,
    required this.assignees,
    required this.qtyByPerson,
    required this.selectedPersonId,
    required this.hint,
    required this.onTap,
    this.priceText,
    this.showPriceEdit = false,
    this.onEditPrice,
    this.onEditNote,
    this.hasNote = false,
    this.isCompact = false,
    this.crewIndexById = const {},
  });

  /// Food name only (one line — height stable when Prices toggles).
  final String title;

  /// e.g. `230 le` when Prices is on; shown trailing, not inside title.
  final String? priceText;
  final List<Person> assignees;
  final Map<String, int> qtyByPerson;
  final String? selectedPersonId;
  final String hint;
  final VoidCallback onTap;
  final bool showPriceEdit;
  final VoidCallback? onEditPrice;
  final VoidCallback? onEditNote;
  final bool hasNote;
  final bool isCompact;

  /// Crew roster order (id → 0-based index) for roman-numeral icons.
  final Map<String, int> crewIndexById;

  @override
  State<FoodTile> createState() => _FoodTileState();
}

class _FoodTileState extends State<FoodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  static const double _editSlot = AppValues.minTouchCompact;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _editPrice() {
    if (widget.onEditPrice == null) return;
    AppHaptics.mediumImpact();
    widget.onEditPrice!();
  }

  void _editNote() {
    if (widget.onEditNote == null) return;
    AppHaptics.selectionClick();
    widget.onEditNote!();
  }

  Widget _noteButton(ColorScheme scheme, Translate t) {
    return SizedBox(
      width: _editSlot,
      height: _editSlot,
      child: IconButton(
        onPressed: _editNote,
        tooltip: t.itemNote,
        icon: Icon(
          widget.hasNote
              ? Icons.sticky_note_2_rounded
              : Icons.note_add_outlined,
          size: 19,
          color: widget.hasNote ? scheme.primary : scheme.onSurfaceVariant,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: _editSlot,
          minHeight: _editSlot,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String get _assigneeSignature {
    if (widget.assignees.isEmpty) return 'empty';
    return widget.assignees
        .map((p) => '${p.id}:${widget.qtyByPerson[p.id] ?? 0}')
        .join('|');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasSelected = widget.selectedPersonId != null &&
        widget.assignees.any((p) => p.id == widget.selectedPersonId);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final iconMs = reduce ? Duration.zero : AppValues.animIconPop;
    final t = Translate.instance;

    final summaryParts = <String>[];
    for (final p in widget.assignees) {
      final q = widget.qtyByPerson[p.id] ?? 0;
      summaryParts.add('${p.name} $q');
    }
    final assigneeLabel =
        summaryParts.isEmpty ? t.emptyOrder : summaryParts.join(', ');
    final priceLabel =
        widget.priceText != null ? ', ${t.priceLabel} ${widget.priceText}' : '';

    return Semantics(
      label: '${widget.title}, $assigneeLabel$priceLabel',
      button: true,
      child: GestureDetector(
        onTapDown: (_) {
          if (!reduce) _press.forward();
        },
        onTapUp: (_) {
          if (!reduce) _press.reverse();
        },
        onTapCancel: () {
          if (!reduce) _press.reverse();
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: child,
            );
          },
          child: SizedBox(
            width: double.infinity,
            child: Material(
              color: scheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
              child: Container(
                width: double.infinity,
                padding: widget.isCompact
                    ? const EdgeInsets.fromLTRB(14, 6, 8, 6)
                    : const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard - 4),
                  border: Border.all(
                    color: hasSelected
                        ? scheme.primary.withValues(alpha: 0.55)
                        : scheme.outlineVariant.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Keep the price edit action in the compact title row.
                    SizedBox(
                      height: _editSlot,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.priceText != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• ${widget.priceText}',
                              maxLines: 1,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ] else if (widget.onEditPrice != null &&
                              !widget.showPriceEdit) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.tapToSetPrice,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                          SizedBox(
                            width: _editSlot,
                            height: _editSlot,
                            child: widget.showPriceEdit &&
                                    widget.onEditPrice != null
                                ? IconButton(
                                    onPressed: _editPrice,
                                    tooltip: t.editFoodPriceTitle,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    color: scheme.primary,
                                    constraints: const BoxConstraints(
                                      minWidth: _editSlot,
                                      minHeight: _editSlot,
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isCompact)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: AnimatedSwitcher(
                          duration: iconMs,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.88, end: 1)
                                  .animate(animation),
                              child: child,
                            ),
                          ),
                          child: widget.assignees.isEmpty
                              ? Row(
                                  key: const ValueKey('empty_hint'),
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.hint,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (widget.onEditNote != null)
                                      _noteButton(scheme, t),
                                  ],
                                )
                              : Padding(
                                  key: ValueKey(_assigneeSignature),
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            for (final p in widget.assignees)
                                              for (var i = 0;
                                                  i <
                                                      (widget.qtyByPerson[
                                                              p.id] ??
                                                          1);
                                                  i++)
                                                PersonFoodIcon(
                                                  key: ValueKey('${p.id}_$i'),
                                                  person: p,
                                                  index: widget.crewIndexById[
                                                          p.id] ??
                                                      0,
                                                  highlighted: p.id ==
                                                      widget.selectedPersonId,
                                                ),
                                          ],
                                        ),
                                      ),
                                      if (widget.onEditNote != null)
                                        _noteButton(scheme, t),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
