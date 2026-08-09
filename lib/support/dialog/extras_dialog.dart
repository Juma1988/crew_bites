import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/translate.dart';

/// Result of the extras dialog: tip (+ optional %) + delivery amounts.
class ExtrasResult {
  const ExtrasResult({
    required this.tip,
    required this.delivery,
    this.tipPercent,
  });

  final double tip;
  final double delivery;

  /// Tip as a % of the food subtotal (null = use the fixed [tip] amount).
  final double? tipPercent;
}

/// Dialog with three fields: Tip (amount), Tip % (optional, of the food
/// subtotal) and Delivery. Tip and Tip % are mutually exclusive — typing in
/// one grays out the other. Returns [ExtrasResult] on save, null on cancel.
Future<ExtrasResult?> showExtrasDialog(
  BuildContext context, {
  double initialTip = 0,
  double initialDelivery = 0,
  double? initialPercent,
  double orderTotal = 0,
}) async {
  final t = Translate.instance;
  final tipCtrl = TextEditingController(
    text: initialTip > 0 ? initialTip.toStringAsFixed(0) : '',
  );
  final pctCtrl = TextEditingController(
    text: (initialPercent ?? 0) > 0 ? initialPercent!.toStringAsFixed(0) : '',
  );
  final deliveryCtrl = TextEditingController(
    text: initialDelivery > 0 ? initialDelivery.toStringAsFixed(0) : '',
  );

  ExtrasResult? result;
  try {
    result = await showDialog<ExtrasResult>(
      context: context,
      builder: (ctx) => _ExtrasDialogBody(
        t: t,
        tipCtrl: tipCtrl,
        pctCtrl: pctCtrl,
        deliveryCtrl: deliveryCtrl,
        orderTotal: orderTotal,
      ),
    );
  } finally {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tipCtrl.dispose();
      pctCtrl.dispose();
      deliveryCtrl.dispose();
    });
  }
  return result;
}

class _ExtrasDialogBody extends StatefulWidget {
  const _ExtrasDialogBody({
    required this.t,
    required this.tipCtrl,
    required this.pctCtrl,
    required this.deliveryCtrl,
    required this.orderTotal,
  });

  final Translate t;
  final TextEditingController tipCtrl;
  final TextEditingController pctCtrl;
  final TextEditingController deliveryCtrl;
  final double orderTotal;

  @override
  State<_ExtrasDialogBody> createState() => _ExtrasDialogBodyState();
}

class _ExtrasDialogBodyState extends State<_ExtrasDialogBody> {
  double? _previewTip;
  bool _tipHasValue = false;
  bool _pctHasValue = false;

  @override
  void initState() {
    super.initState();
    widget.tipCtrl.addListener(_refresh);
    widget.pctCtrl.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    widget.tipCtrl.removeListener(_refresh);
    widget.pctCtrl.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final tip = double.tryParse(
      widget.tipCtrl.text.trim().replaceAll(',', '.'),
    );
    final pct = double.tryParse(
      widget.pctCtrl.text.trim().replaceAll(',', '.'),
    );
    final preview =
        (pct != null && pct > 0) ? widget.orderTotal * pct / 100 : null;
    setState(() {
      _tipHasValue = tip != null && tip > 0;
      _pctHasValue = pct != null && pct > 0;
      _previewTip = preview;
    });
  }

  /// Tip suggestions that push the food total up to a clean multiple of 10.
  List<double> _suggestions() {
    if (widget.orderTotal <= 0) return [];
    final base = widget.orderTotal.ceilToDouble();
    var target = (base / 10).ceil() * 10;
    if (target <= base) target += 10;
    return [target, target + 10, target + 20]
        .map((v) => v - widget.orderTotal)
        .where((tip) => tip > 0)
        .toList();
  }

  void _applySuggestion(double tip) {
    widget.pctCtrl.clear();
    widget.tipCtrl.text = tip.round().toString();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final preview = _previewTip;
    final suggestions = _suggestions();
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      title: Text(t.extrasSectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Delivery first — it adds to the bill the tip % scales from.
          TextField(
            controller: widget.deliveryCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: t.deliveryLabel,
              hintText: t.deliveryHint,
              suffixText: t.currencySuffix,
            ),
          ),
          const SizedBox(height: 12),
          // Tip suggestions: round the order total up to a multiple of 10.
          if (suggestions.isNotEmpty && !_pctHasValue) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tip in suggestions)
                  ActionChip(
                    label: Text(() {
                      final applied = tip.round();
                      return '$applied${t.currencySuffix} → '
                          '${(widget.orderTotal + applied).round()}';
                    }()),
                    onPressed: () => _applySuggestion(tip),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: widget.tipCtrl,
            enabled: !_pctHasValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: t.tipLabel,
              hintText: t.tipHint,
              suffixText: t.currencySuffix,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.pctCtrl,
            enabled: !_tipHasValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: t.tipPercentLabel,
              hintText: t.tipPercentHint,
              suffixText: '%',
              helperText:
                  preview != null ? t.tipApprox(preview) : t.tipPercentOrBody,
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 6),
          // Show the food total the % is calculated from.
          Text(
            '${t.foodSubtotalLabel}: ${t.money(widget.orderTotal)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            final pct = double.tryParse(
              widget.pctCtrl.text.trim().replaceAll(',', '.'),
            );
            final double tip;
            final double? tipPercent;
            if (pct != null && pct > 0) {
              tipPercent = pct;
              tip = widget.orderTotal * pct / 100;
            } else {
              tipPercent = null;
              tip = double.tryParse(
                    widget.tipCtrl.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;
            }
            final delivery = double.tryParse(
                  widget.deliveryCtrl.text.trim().replaceAll(',', '.'),
                ) ??
                0;
            Navigator.pop(
              context,
              ExtrasResult(
                  tip: tip, delivery: delivery, tipPercent: tipPercent),
            );
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
