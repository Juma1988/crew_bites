import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_101/core/theme.dart';
import 'package:app_101/core/translate.dart';
import 'package:app_101/core/states/order_store.dart';

/// Dialog to fill unit prices for foods that still have price ≤ 0.
class MissingPricesDialog extends StatefulWidget {
  const MissingPricesDialog({
    super.key,
    required this.foods,
    required this.t,
    this.initialPrices = const {},
  });

  final List<String> foods;
  final Translate t;
  /// Lowercase title → suggested unit price (from bundle).
  final Map<String, double> initialPrices;

  @override
  State<MissingPricesDialog> createState() => _MissingPricesDialogState();
}

class _MissingPricesDialogState extends State<MissingPricesDialog> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _unknown;
  late final List<FocusNode> _focusNodes;

  Translate get t => widget.t;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.foods)
        f: TextEditingController(
          text: () {
            final hint = widget.initialPrices[f.toLowerCase()];
            if (hint == null || hint <= 0) return '';
            return OrderStore.formatPrice(hint);
          }(),
        ),
    };
    _unknown = {for (final f in widget.foods) f: false};
    _focusNodes = [for (final _ in widget.foods) FocusNode()];
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  /// Keyboard Next: jump to the next enabled price field (even if empty).
  void _focusNext(int fromIndex) {
    for (var i = fromIndex + 1; i < widget.foods.length; i++) {
      if (_unknown[widget.foods[i]] == true) continue;
      _focusNodes[i].requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
  }

  void _submit() {
    final out = <String, double>{};
    for (final food in widget.foods) {
      if (_unknown[food] == true) {
        out[food] = 0;
        continue;
      }
      final raw = _controllers[food]!.text.trim().replaceAll(',', '.');
      final value = double.tryParse(raw);
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.missingPricesInvalid)),
        );
        return;
      }
      out[food] = value;
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      title: Text(t.missingPricesTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.missingPricesBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final (i, food) in widget.foods.indexed) ...[
                Text(
                  t.foodTitle(food),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controllers[food],
                  focusNode: _focusNodes[i],
                  autofocus: i == 0 && !(_unknown[food] ?? false),
                  enabled: !(_unknown[food] ?? false),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: i == widget.foods.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onSubmitted: i == widget.foods.length - 1
                      ? (_) => _submit()
                      : (_) => _focusNext(i),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: t.priceLabel,
                    hintText: t.priceHint,
                    suffixText: t.currencySuffix,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(t.priceUnknownCheckbox),
                  value: _unknown[food] ?? false,
                  onChanged: (v) {
                    setState(() {
                      _unknown[food] = v ?? false;
                      if (_unknown[food] == true) {
                        _controllers[food]!.clear();
                        _focusNodes[i].unfocus();
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(t.missingPricesContinue),
        ),
      ],
    );
  }
}
