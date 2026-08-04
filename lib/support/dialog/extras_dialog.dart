import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/translate.dart';

/// Result of the extras dialog: tip + delivery amounts.
class ExtrasResult {
  const ExtrasResult({required this.tip, required this.delivery});
  final double tip;
  final double delivery;
}

/// Dialog with two text fields: Tip and Delivery.
/// Returns [ExtrasResult] on save, null on cancel.
Future<ExtrasResult?> showExtrasDialog(
  BuildContext context, {
  double initialTip = 0,
  double initialDelivery = 0,
}) async {
  final t = Translate.instance;
  final tipCtrl = TextEditingController(
    text: initialTip > 0 ? initialTip.toStringAsFixed(0) : '',
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
        deliveryCtrl: deliveryCtrl,
      ),
    );
  } finally {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tipCtrl.dispose();
      deliveryCtrl.dispose();
    });
  }
  return result;
}

class _ExtrasDialogBody extends StatefulWidget {
  const _ExtrasDialogBody({
    required this.t,
    required this.tipCtrl,
    required this.deliveryCtrl,
  });

  final Translate t;
  final TextEditingController tipCtrl;
  final TextEditingController deliveryCtrl;

  @override
  State<_ExtrasDialogBody> createState() => _ExtrasDialogBodyState();
}

class _ExtrasDialogBodyState extends State<_ExtrasDialogBody> {
  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      title: Text(t.extrasSectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.tipCtrl,
            autofocus: true,
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
            controller: widget.deliveryCtrl,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            final tip = double.tryParse(
                  widget.tipCtrl.text.trim().replaceAll(',', '.'),
                ) ??
                0;
            final delivery = double.tryParse(
                  widget.deliveryCtrl.text.trim().replaceAll(',', '.'),
                ) ??
                0;
            Navigator.pop(
                context, ExtrasResult(tip: tip, delivery: delivery));
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
