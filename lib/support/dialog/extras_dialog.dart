import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/translate.dart';
import '../../core/values/app_values.dart';
import '../../models/order_models.dart';

/// Result of the extras dialog with all 4 category fields.
class ExtrasResult {
  const ExtrasResult({
    required this.activeCategory,
    required this.field,
    required this.allFields,
  });

  final ExtrasCategory activeCategory;
  final ExtrasField field;
  final Map<ExtrasCategory, ExtrasField> allFields;

  bool get hasValue => field.hasValue;

  @override
  String toString() => 'ExtrasResult(active: $activeCategory, value: $field)';
}

/// Add-ons dialog: list of 4 sections (Service, Tax, Tip, Delivery)
/// separated by dividers. All sections visible at once.
class _ExtrasDialog extends StatefulWidget {
  const _ExtrasDialog({
    required this.context,
    required this.initialTip,
    required this.initialDelivery,
    required this.initialTax,
    required this.initialService,
    required this.orderTotal,
  });

  final BuildContext context;
  final ExtrasField initialTip;
  final ExtrasField initialDelivery;
  final ExtrasField initialTax;
  final ExtrasField initialService;
  final double orderTotal;

  @override
  State<_ExtrasDialog> createState() => _ExtrasDialogState();
}

class _ExtrasDialogState extends State<_ExtrasDialog> {
  late Map<ExtrasCategory, ExtrasField> fields;

  TextEditingController _svcPctCtrl = TextEditingController();
  TextEditingController _svcAmtCtrl = TextEditingController();
  TextEditingController _taxPctCtrl = TextEditingController();
  TextEditingController _taxAmtCtrl = TextEditingController();
  TextEditingController _tipPctCtrl = TextEditingController();
  TextEditingController _tipAmtCtrl = TextEditingController();
  TextEditingController _deliveryCtrl = TextEditingController();

  bool _deliveryCustom = false;

  static const _deliverySuggestions = [15.0, 25.0, 40.0];

  @override
  void initState() {
    super.initState();
    final svc = widget.initialService;
    final tax = widget.initialTax;
    var tip = widget.initialTip;
    final delivery = widget.initialDelivery;

    // Tip always defaults to percent mode.
    if (!tip.usePercent && !tip.hasValue) {
      tip = const ExtrasField(percent: 0, usePercent: true);
    }

    fields = {
      ExtrasCategory.service: svc,
      ExtrasCategory.tax: tax,
      ExtrasCategory.tip: tip,
      ExtrasCategory.delivery: delivery,
    };

    _svcPctCtrl = TextEditingController(
      text: svc.usePercent && svc.percent != null ? svc.percent!.toStringAsFixed(0) : '',
    );
    _svcAmtCtrl = TextEditingController(
      text: !svc.usePercent && svc.amount > 0 ? svc.amount.toStringAsFixed(0) : '',
    );
    _taxPctCtrl = TextEditingController(
      text: tax.usePercent && tax.percent != null ? tax.percent!.toStringAsFixed(0) : '',
    );
    _taxAmtCtrl = TextEditingController(
      text: !tax.usePercent && tax.amount > 0 ? tax.amount.toStringAsFixed(0) : '',
    );
    _tipPctCtrl = TextEditingController(
      text: tip.usePercent && tip.percent != null ? tip.percent!.toStringAsFixed(0) : '',
    );
    _tipAmtCtrl = TextEditingController(
      text: !tip.usePercent && tip.amount > 0 ? tip.amount.toStringAsFixed(0) : '',
    );
    _deliveryCtrl = TextEditingController(
      text: delivery.amount > 0 ? delivery.amount.toStringAsFixed(0) : '',
    );
    _deliveryCustom = delivery.hasValue && !_deliverySuggestions.any((a) => a == delivery.amount);
  }

  @override
  void dispose() {
    _svcPctCtrl.dispose();
    _svcAmtCtrl.dispose();
    _taxPctCtrl.dispose();
    _taxAmtCtrl.dispose();
    _tipPctCtrl.dispose();
    _tipAmtCtrl.dispose();
    _deliveryCtrl.dispose();
    super.dispose();
  }

  // ── Service ──

  void _onServicePctChanged(double pct) {
    final v = pct.roundToDouble();
    fields[ExtrasCategory.service] =
        ExtrasField(percent: v, usePercent: true).copyWith(clearPercent: v <= 0);
    _svcPctCtrl.text = v > 0 ? v.toStringAsFixed(0) : '';
    setState(() {});
  }

  void _onServiceAmtChanged(String text) {
    final amt = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    fields[ExtrasCategory.service] = ExtrasField(amount: amt, usePercent: false);
    setState(() {});
  }

  void _toggleServiceMode() {
    final f = fields[ExtrasCategory.service]!;
    if (f.usePercent) {
      final amt = (f.percent ?? 0) * widget.orderTotal / 100;
      fields[ExtrasCategory.service] = ExtrasField(amount: amt, usePercent: false);
      _svcAmtCtrl.text = amt > 0 ? amt.toStringAsFixed(0) : '';
      _svcPctCtrl.text = '';
    } else {
      final pct = f.amount > 0 && widget.orderTotal > 0
          ? (f.amount / widget.orderTotal * 100).roundToDouble()
          : 0.0;
      fields[ExtrasCategory.service] =
          ExtrasField(percent: pct, usePercent: true).copyWith(clearPercent: pct <= 0);
      _svcPctCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
      _svcAmtCtrl.text = '';
    }
    setState(() {});
  }

  // ── Tax ──

  void _onTaxPctChanged(double pct) {
    final v = pct.roundToDouble();
    fields[ExtrasCategory.tax] =
        ExtrasField(percent: v, usePercent: true).copyWith(clearPercent: v <= 0);
    _taxPctCtrl.text = v > 0 ? v.toStringAsFixed(0) : '';
    setState(() {});
  }

  void _onTaxAmtChanged(String text) {
    final amt = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    fields[ExtrasCategory.tax] = ExtrasField(amount: amt, usePercent: false);
    setState(() {});
  }

  void _toggleTaxMode() {
    final f = fields[ExtrasCategory.tax]!;
    if (f.usePercent) {
      final amt = (f.percent ?? 0) * widget.orderTotal / 100;
      fields[ExtrasCategory.tax] = ExtrasField(amount: amt, usePercent: false);
      _taxAmtCtrl.text = amt > 0 ? amt.toStringAsFixed(0) : '';
      _taxPctCtrl.text = '';
    } else {
      final pct = f.amount > 0 && widget.orderTotal > 0
          ? (f.amount / widget.orderTotal * 100).roundToDouble()
          : 0.0;
      fields[ExtrasCategory.tax] =
          ExtrasField(percent: pct, usePercent: true).copyWith(clearPercent: pct <= 0);
      _taxPctCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
      _taxAmtCtrl.text = '';
    }
    setState(() {});
  }

  // ── Tip ──

  void _onTipPctChanged(double pct) {
    final v = pct.roundToDouble();
    final calculated = widget.orderTotal * v / 100;
    fields[ExtrasCategory.tip] = ExtrasField(
      amount: calculated,
      percent: v,
      usePercent: true,
    ).copyWith(clearPercent: v <= 0);
    _tipPctCtrl.text = v > 0 ? v.toStringAsFixed(0) : '';
    setState(() {});
  }

  void _onTipAmtChanged(String text) {
    final amt = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    fields[ExtrasCategory.tip] = ExtrasField(amount: amt, usePercent: false);
    setState(() {});
  }

  void _toggleTipMode() {
    final f = fields[ExtrasCategory.tip]!;
    if (f.usePercent) {
      final amt = (f.percent ?? 0) * widget.orderTotal / 100;
      fields[ExtrasCategory.tip] = ExtrasField(amount: amt, usePercent: false);
      _tipAmtCtrl.text = amt > 0 ? amt.toStringAsFixed(0) : '';
      _tipPctCtrl.text = '';
    } else {
      final pct = f.amount > 0 && widget.orderTotal > 0
          ? (f.amount / widget.orderTotal * 100).roundToDouble()
          : 0.0;
      final calculated = widget.orderTotal * pct / 100;
      fields[ExtrasCategory.tip] = ExtrasField(amount: calculated, percent: pct, usePercent: true)
          .copyWith(clearPercent: pct <= 0);
      _tipPctCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
      _tipAmtCtrl.text = '';
    }
    setState(() {});
  }

  // ── Delivery ──

  void _applyDeliverySuggestion(double amt) {
    final current = fields[ExtrasCategory.delivery]!;
    if (!current.usePercent && current.amount == amt) {
      fields[ExtrasCategory.delivery] = const ExtrasField();
      _deliveryCtrl.text = '';
      _deliveryCustom = false;
    } else {
      fields[ExtrasCategory.delivery] = ExtrasField(amount: amt, usePercent: false);
      _deliveryCtrl.text = amt.toStringAsFixed(0);
      _deliveryCustom = false;
    }
    setState(() {});
  }

  void _onDeliveryCustomChanged(String text) {
    final amt = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    fields[ExtrasCategory.delivery] = ExtrasField(amount: amt, usePercent: false);
    _deliveryCustom = text.isNotEmpty;
    setState(() {});
  }

  // ── Save ──

  void save() {
    Navigator.pop(
      widget.context,
      ExtrasResult(
        activeCategory: ExtrasCategory.service,
        field: fields[ExtrasCategory.service]!,
        allFields: Map.from(fields),
      ),
    );
  }

  // ── Helpers ──

  IconData _icon(ExtrasCategory cat) => switch (cat) {
        ExtrasCategory.service => Icons.handshake_rounded,
        ExtrasCategory.tax => Icons.receipt_long_rounded,
        ExtrasCategory.delivery => Icons.local_shipping_rounded,
        ExtrasCategory.tip => Icons.attach_money_rounded,
      };

  String _label(ExtrasCategory cat) => switch (cat) {
        ExtrasCategory.service => Translate.instance.serviceLabel,
        ExtrasCategory.tax => Translate.instance.taxLabel,
        ExtrasCategory.delivery => Translate.instance.deliveryLabel,
        ExtrasCategory.tip => Translate.instance.tipLabel,
      };

  String _preview(ExtrasCategory cat) {
    final t = Translate.instance;
    final f = fields[cat]!;
    if (!f.usePercent || f.percent == null || f.percent! <= 0) return '';
    final calc = widget.orderTotal * f.percent! / 100;
    return cat == ExtrasCategory.service
        ? t.serviceApprox(calc)
        : cat == ExtrasCategory.tax
            ? t.taxApprox(calc)
            : t.tipApprox(calc);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final t = Translate.instance;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppTheme.radiusCard);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: radius),
      title: Text(t.extrasDialogTitle),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildServiceSection(scheme, t),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
              _buildTaxSection(scheme, t),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
              _buildTipSection(scheme, t),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
              _buildDeliverySection(scheme, t),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: save,
              child: Text(t.confirmAction),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section: Service ──

  Widget _buildServiceSection(ColorScheme scheme, Translate t) {
    final f = fields[ExtrasCategory.service]!;
    final usePct = f.usePercent;
    final pct = usePct ? (f.percent ?? 0) : 0.0;
    final preview = _preview(ExtrasCategory.service);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(ExtrasCategory.service, scheme),
          const SizedBox(height: 8),
          if (usePct) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: pct.clamp(0.0, 25.0),
                    min: 0,
                    max: 25,
                    divisions: 50,
                    label: '${pct.round()}%',
                    onChanged: _onServicePctChanged,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showPctInputDialog(ExtrasCategory.service, f),
                  child: Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pct.round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14, color: scheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: preview.isNotEmpty ? 1 : 0,
              child: Text(preview.isNotEmpty ? preview : ' ',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleServiceMode,
              child: Text(t.orEnterFixedAmount,
                  style:
                      TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ] else ...[
            TextField(
              controller: _svcAmtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration:
                  InputDecoration(hintText: '0', suffixText: t.currencySuffix, isDense: true),
              onChanged: _onServiceAmtChanged,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleServiceMode,
              child: Text(t.orEnterPercent,
                  style:
                      TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: Tax ──

  Widget _buildTaxSection(ColorScheme scheme, Translate t) {
    final f = fields[ExtrasCategory.tax]!;
    final usePct = f.usePercent;
    final pct = usePct ? (f.percent ?? 0) : 0.0;
    final preview = _preview(ExtrasCategory.tax);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(ExtrasCategory.tax, scheme),
          const SizedBox(height: 8),
          if (usePct) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: pct.clamp(0.0, 25.0),
                    min: 0,
                    max: 25,
                    divisions: 50,
                    label: '${pct.round()}%',
                    onChanged: _onTaxPctChanged,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showPctInputDialog(ExtrasCategory.tax, f),
                  child: Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pct.round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14, color: scheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: preview.isNotEmpty ? 1 : 0,
              child: Text(preview.isNotEmpty ? preview : ' ',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleTaxMode,
              child: Text(t.orEnterFixedAmount,
                  style:
                      TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ] else ...[
            TextField(
              controller: _taxAmtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration:
                  InputDecoration(hintText: '0', suffixText: t.currencySuffix, isDense: true),
              onChanged: _onTaxAmtChanged,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleTaxMode,
              child: Text(t.orEnterPercent,
                  style:
                      TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: Tip ──

  Widget _buildTipSection(ColorScheme scheme, Translate t) {
    final f = fields[ExtrasCategory.tip]!;
    final usePct = f.usePercent;
    final pct = usePct ? (f.percent ?? 0) : 0.0;
    final tipValue =
        usePct && f.percent != null && f.percent! > 0 ? widget.orderTotal * f.percent! / 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(ExtrasCategory.tip, scheme),
          const SizedBox(height: 8),
          if (usePct) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: pct.clamp(0.0, 25.0),
                    min: 0,
                    max: 25,
                    divisions: 50,
                    label: '${pct.round()}%',
                    onChanged: _onTipPctChanged,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showPctInputDialog(ExtrasCategory.tip, f),
                  child: Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pct.round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14, color: scheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: 1,
              child: Text(
                t.tipApprox(tipValue),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleTipMode,
              child: Text(t.orEnterFixedAmount,
                  style:
                      TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ] else ...[
            TextField(
              controller: _tipAmtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration:
                  InputDecoration(hintText: '0', suffixText: t.currencySuffix, isDense: true),
              onChanged: _onTipAmtChanged,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleTipMode,
              child: Text(t.orEnterPercent,
                  style:
                      TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: Delivery ──

  Widget _buildDeliverySection(ColorScheme scheme, Translate t) {
    final f = fields[ExtrasCategory.delivery]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(ExtrasCategory.delivery, scheme),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final amt in _deliverySuggestions) ...[
                Expanded(
                  child: _SuggestionChip(
                    label: '${amt.toInt()}',
                    selected: !f.usePercent && f.amount == amt,
                    onTap: () => _applyDeliverySuggestion(amt),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _deliveryCustom
                          ? scheme.primary.withValues(alpha: 0.1)
                          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppValues.radiusChip),
                      border: Border.all(
                        color: _deliveryCustom
                            ? scheme.primary
                            : scheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
                      controller: _deliveryCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _deliveryCustom ? scheme.primary : null),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '···',
                        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: _onDeliveryCustomChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared ──

  Widget _sectionHeader(ExtrasCategory cat, ColorScheme scheme) {
    final f = fields[cat]!;
    final hasVal = f.hasValue;
    return Row(
      children: [
        Icon(_icon(cat), size: 18, color: hasVal ? Colors.green : scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          _label(cat),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: hasVal ? Colors.green[700] : null,
          ),
        ),
      ],
    );
  }

  void _showPctInputDialog(ExtrasCategory cat, ExtrasField field) {
    final ctrl = TextEditingController(
      text: (field.percent ?? 0).round().toString(),
    );
    final t = Translate.instance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
        title: Text('${_label(cat)} %'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: '%'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 0;
              final pct = v.clamp(0.0, 25.0);
              final calculated = widget.orderTotal * pct / 100;
              fields[cat] = ExtrasField(amount: calculated, percent: pct, usePercent: true)
                  .copyWith(clearPercent: pct <= 0);
              if (cat == ExtrasCategory.service) {
                _svcPctCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
              } else if (cat == ExtrasCategory.tax) {
                _taxPctCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
              } else {
                _tipPctCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppValues.radiusChip),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? scheme.onPrimary : null,
          ),
        ),
      ),
    );
  }
}

/// Shows the add-ons dialog and returns the [ExtrasResult] or null if cancelled.
Future<ExtrasResult?> showExtrasDialog(
  BuildContext context, {
  ExtrasCategory initialCategory = ExtrasCategory.tip,
  required ExtrasField initialTip,
  required ExtrasField initialDelivery,
  required ExtrasField initialTax,
  required ExtrasField initialService,
  double orderTotal = 0,
}) async {
  final result = await showDialog<ExtrasResult?>(
    context: context,
    builder: (ctx) => _ExtrasDialog(
      context: ctx,
      initialTip: initialTip,
      initialDelivery: initialDelivery,
      initialTax: initialTax,
      initialService: initialService,
      orderTotal: orderTotal,
    ),
  );
  return result;
}
