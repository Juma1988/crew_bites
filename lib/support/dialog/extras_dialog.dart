import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/translate.dart';
import '../../core/values/app_values.dart';
import '../../core/debug/debug_registry.dart';
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
  final Set<ExtrasCategory> _disabledCategories = <ExtrasCategory>{};
  final Set<ExtrasCategory> _collapsedCategories = <ExtrasCategory>{};
  late Map<ExtrasCategory, ExtrasField> _initialFields;
  late Set<ExtrasCategory> _initialDisabledCategories;
  bool _handlingBack = false;

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
    final svc = _defaultMode(ExtrasCategory.service, widget.initialService);
    final tax = _defaultMode(ExtrasCategory.tax, widget.initialTax);
    var tip = widget.initialTip;
    final delivery = widget.initialDelivery;

    // A new tip starts as a fixed amount; percentage is the alternate mode.
    if (tip.usePercent && !tip.hasValue) {
      tip = const ExtrasField();
    }

    fields = {
      ExtrasCategory.service: svc,
      ExtrasCategory.tax: tax,
      ExtrasCategory.tip: tip,
      ExtrasCategory.delivery: delivery,
    };
    for (final entry in fields.entries) {
      if (!entry.value.hasValue) {
        _disabledCategories.add(entry.key);
        _collapsedCategories.add(entry.key);
      }
    }
    final firstEnabled = fields.keys.firstWhere(
      (category) => !_disabledCategories.contains(category),
      orElse: () => ExtrasCategory.tip,
    );
    _collapseOtherCategories(firstEnabled);
    _initialFields = Map<ExtrasCategory, ExtrasField>.from(fields);
    _initialDisabledCategories = Set<ExtrasCategory>.from(_disabledCategories);

    _svcPctCtrl = TextEditingController(
      text: svc.usePercent && svc.percent != null
          ? svc.percent!.toStringAsFixed(0)
          : '',
    );
    _svcAmtCtrl = TextEditingController(
      text: !svc.usePercent && svc.amount > 0
          ? svc.amount.toStringAsFixed(0)
          : '',
    );
    _taxPctCtrl = TextEditingController(
      text: tax.usePercent && tax.percent != null
          ? tax.percent!.toStringAsFixed(0)
          : '',
    );
    _taxAmtCtrl = TextEditingController(
      text: !tax.usePercent && tax.amount > 0
          ? tax.amount.toStringAsFixed(0)
          : '',
    );
    _tipPctCtrl = TextEditingController(
      text: tip.usePercent && tip.percent != null
          ? tip.percent!.toStringAsFixed(0)
          : '',
    );
    _tipAmtCtrl = TextEditingController(
      text: !tip.usePercent && tip.amount > 0
          ? tip.amount.toStringAsFixed(0)
          : '',
    );
    _deliveryCtrl = TextEditingController(
      text: delivery.amount > 0 ? delivery.amount.toStringAsFixed(0) : '',
    );
    _deliveryCustom = delivery.hasValue &&
        !_deliverySuggestions.any((a) => a == delivery.amount);
  }

  ExtrasField _defaultMode(ExtrasCategory category, ExtrasField field) {
    if (field.hasValue) return field;
    return switch (category) {
      ExtrasCategory.service ||
      ExtrasCategory.tax =>
        const ExtrasField(percent: 0, usePercent: true),
      ExtrasCategory.tip || ExtrasCategory.delivery => const ExtrasField(),
    };
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
    fields[ExtrasCategory.service] = ExtrasField(percent: v, usePercent: true)
        .copyWith(clearPercent: v <= 0);
    _svcPctCtrl.text = v > 0 ? v.toStringAsFixed(0) : '';
    setState(() {});
  }

  void _onServiceAmtChanged(String text) {
    final amt = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    fields[ExtrasCategory.service] =
        ExtrasField(amount: amt, usePercent: false);
    setState(() {});
  }

  void _toggleServiceMode() {
    final f = fields[ExtrasCategory.service]!;
    if (f.usePercent) {
      final amt = (f.percent ?? 0) * widget.orderTotal / 100;
      fields[ExtrasCategory.service] =
          ExtrasField(amount: amt, usePercent: false);
      _svcAmtCtrl.text = amt > 0 ? amt.toStringAsFixed(0) : '';
      _svcPctCtrl.text = '';
    } else {
      final pct = f.amount > 0 && widget.orderTotal > 0
          ? (f.amount / widget.orderTotal * 100).roundToDouble()
          : 0.0;
      fields[ExtrasCategory.service] =
          ExtrasField(percent: pct, usePercent: true)
              .copyWith(clearPercent: pct <= 0);
      _svcPctCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
      _svcAmtCtrl.text = '';
    }
    setState(() {});
  }

  // ── Tax ──

  void _onTaxPctChanged(double pct) {
    final v = pct.roundToDouble();
    fields[ExtrasCategory.tax] = ExtrasField(percent: v, usePercent: true)
        .copyWith(clearPercent: v <= 0);
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
      fields[ExtrasCategory.tax] = ExtrasField(percent: pct, usePercent: true)
          .copyWith(clearPercent: pct <= 0);
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
      fields[ExtrasCategory.tip] =
          ExtrasField(amount: calculated, percent: pct, usePercent: true)
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
      fields[ExtrasCategory.delivery] =
          ExtrasField(amount: amt, usePercent: false);
      _deliveryCtrl.text = amt.toStringAsFixed(0);
      _deliveryCustom = false;
    }
    setState(() {});
  }

  void _onDeliveryCustomChanged(String text) {
    final amt = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    fields[ExtrasCategory.delivery] =
        ExtrasField(amount: amt, usePercent: false);
    _deliveryCustom = text.isNotEmpty;
    setState(() {});
  }

  // ── Save ──

  void save() {
    final savedFields = <ExtrasCategory, ExtrasField>{
      for (final entry in fields.entries)
        entry.key: _disabledCategories.contains(entry.key)
            ? const ExtrasField()
            : entry.value,
    };
    Navigator.pop(
      widget.context,
      ExtrasResult(
        activeCategory: ExtrasCategory.service,
        field: savedFields[ExtrasCategory.service]!,
        allFields: savedFields,
      ),
    );
  }

  void _toggleCategory(ExtrasCategory category) {
    setState(() {
      if (_disabledCategories.contains(category)) {
        _disabledCategories.remove(category);
        _collapsedCategories.remove(category);
        _collapseOtherCategories(category);
      } else {
        _disabledCategories.add(category);
        _collapsedCategories.add(category);
      }
    });
  }

  void _toggleCollapsed(ExtrasCategory category) {
    if (_disabledCategories.contains(category)) return;
    setState(() {
      if (!_collapsedCategories.add(category)) {
        _collapsedCategories.remove(category);
        _collapseOtherCategories(category);
      }
    });
  }

  void _collapseOtherCategories(ExtrasCategory openCategory) {
    _collapsedCategories.addAll(
      ExtrasCategory.values.where((category) => category != openCategory),
    );
  }

  bool get _hasUnsavedChanges {
    if (!_disabledCategories.containsAll(_initialDisabledCategories) ||
        !_initialDisabledCategories.containsAll(_disabledCategories)) {
      return true;
    }
    for (final category in fields.keys) {
      final before = _initialFields[category]!;
      final current = fields[category]!;
      if (before.amount != current.amount ||
          before.percent != current.percent ||
          before.usePercent != current.usePercent) {
        return true;
      }
    }
    return false;
  }

  double get _totalBill {
    return widget.orderTotal + _addonsTotal;
  }

  double get _addonsTotal {
    var total = 0.0;
    for (final entry in fields.entries) {
      if (!_disabledCategories.contains(entry.key)) {
        total += entry.value.effectiveAmount(widget.orderTotal);
      }
    }
    return total;
  }

  Future<void> _handleBack() async {
    if (_handlingBack) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.pop(widget.context);
      return;
    }

    _handlingBack = true;
    final discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(Translate.instance.discardChangesTitle),
        content: Text(Translate.instance.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(Translate.instance.goBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(Translate.instance.discardChanges),
          ),
        ],
      ),
    );
    _handlingBack = false;
    if (discard == true && mounted) Navigator.pop(context);
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
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(440.0, screenSize.width - 32);
    final dialogHeight = math.min(660.0, screenSize.height - 80);
    if (DebugRegistry.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugRegistry.currentFile.value =
            'lib/support/dialog/extras_dialog.dart';
      });
    }

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: radius),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.tune_rounded, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.extrasDialogTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionCard(scheme, _buildServiceSection(scheme, t)),
                _sectionCard(scheme, _buildTaxSection(scheme, t)),
                _sectionCard(scheme, _buildTipSection(scheme, t)),
                _sectionCard(scheme, _buildDeliverySection(scheme, t)),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.grandTotalLabel(_totalBill, _addonsTotal),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.check_rounded),
              label: Text(t.confirmAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(ColorScheme scheme, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  // ── Section: Service ──

  Widget _buildServiceSection(ColorScheme scheme, Translate t) {
    if (_disabledCategories.contains(ExtrasCategory.service) ||
        _collapsedCategories.contains(ExtrasCategory.service)) {
      return _disabledSection(ExtrasCategory.service, scheme);
    }
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
                      border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pct.round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: scheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: preview.isNotEmpty ? 1 : 0,
              child: Text(preview.isNotEmpty ? preview : ' ',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _toggleServiceMode,
                icon: const Icon(Icons.currency_exchange_rounded, size: 16),
                label: Text(t.orEnterFixedAmount),
              ),
            ),
          ] else ...[
            TextField(
              controller: _svcAmtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: InputDecoration(
                  hintText: '0', suffixText: t.currencySuffix, isDense: true),
              onChanged: _onServiceAmtChanged,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _toggleServiceMode,
                icon: const Icon(Icons.percent_rounded, size: 16),
                label: Text(t.orEnterPercent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: Tax ──

  Widget _buildTaxSection(ColorScheme scheme, Translate t) {
    if (_disabledCategories.contains(ExtrasCategory.tax) ||
        _collapsedCategories.contains(ExtrasCategory.tax)) {
      return _disabledSection(ExtrasCategory.tax, scheme);
    }
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
                      border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pct.round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: scheme.primary),
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: preview.isNotEmpty ? 1 : 0,
              child: Text(preview.isNotEmpty ? preview : ' ',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _toggleTaxMode,
                icon: const Icon(Icons.currency_exchange_rounded, size: 16),
                label: Text(t.orEnterFixedAmount),
              ),
            ),
          ] else ...[
            TextField(
              controller: _taxAmtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: InputDecoration(
                  hintText: '0', suffixText: t.currencySuffix, isDense: true),
              onChanged: _onTaxAmtChanged,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _toggleTaxMode,
                icon: const Icon(Icons.percent_rounded, size: 16),
                label: Text(t.orEnterPercent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: Tip ──

  Widget _buildTipSection(ColorScheme scheme, Translate t) {
    if (_disabledCategories.contains(ExtrasCategory.tip) ||
        _collapsedCategories.contains(ExtrasCategory.tip)) {
      return _disabledSection(ExtrasCategory.tip, scheme);
    }
    final f = fields[ExtrasCategory.tip]!;
    final usePct = f.usePercent;
    final pct = usePct ? (f.percent ?? 0) : 0.0;
    final tipValue = usePct && f.percent != null && f.percent! > 0
        ? widget.orderTotal * f.percent! / 100
        : 0.0;

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
                      border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pct.round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: scheme.primary),
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _toggleTipMode,
                icon: const Icon(Icons.currency_exchange_rounded, size: 16),
                label: Text(t.orEnterFixedAmount),
              ),
            ),
          ] else ...[
            TextField(
              controller: _tipAmtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: InputDecoration(
                  hintText: '0', suffixText: t.currencySuffix, isDense: true),
              onChanged: _onTipAmtChanged,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _toggleTipMode,
                icon: const Icon(Icons.percent_rounded, size: 16),
                label: Text(t.orEnterPercent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section: Delivery ──

  Widget _buildDeliverySection(ColorScheme scheme, Translate t) {
    if (_disabledCategories.contains(ExtrasCategory.delivery) ||
        _collapsedCategories.contains(ExtrasCategory.delivery)) {
      return _disabledSection(ExtrasCategory.delivery, scheme);
    }
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _deliveryCustom
                          ? scheme.primary.withValues(alpha: 0.1)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                      ],
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
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
    final disabled = _disabledCategories.contains(cat);
    final value = !disabled && _collapsedCategories.contains(cat) && hasVal
        ? Translate.instance.money(
            f.effectiveAmount(widget.orderTotal),
            hideZero: true,
          )
        : '';
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: disabled
                    ? () => _toggleCategory(cat)
                    : () => _toggleCollapsed(cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _icon(cat),
                        size: 20,
                        color: disabled
                            ? scheme.onSurfaceVariant
                            : hasVal
                                ? Colors.green
                                : scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: _label(cat)),
                              if (value.isNotEmpty)
                                TextSpan(
                                  text: ' · $value',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: disabled
                                ? scheme.onSurfaceVariant
                                : hasVal
                                    ? Colors.green[700]
                                    : null,
                          ),
                        ),
                      ),
                      if (!disabled)
                        Icon(
                          _collapsedCategories.contains(cat)
                              ? Icons.expand_more_rounded
                              : Icons.expand_less_rounded,
                          size: 20,
                          color: Colors.green,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip:
                  disabled ? 'Enable ${_label(cat)}' : 'Disable ${_label(cat)}',
              onPressed: () => _toggleCategory(cat),
              icon: Icon(
                disabled ? Icons.add_rounded : Icons.remove_rounded,
                color: disabled ? scheme.onSurfaceVariant : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disabledSection(ExtrasCategory category, ColorScheme scheme) {
    return _sectionHeader(category, scheme);
  }

  void _showPctInputDialog(ExtrasCategory cat, ExtrasField field) {
    final ctrl = TextEditingController(
      text: (field.percent ?? 0).round().toString(),
    );
    final t = Translate.instance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
        title: Text('${_label(cat)} %'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: '%'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 0;
              final pct = v.clamp(0.0, 25.0);
              final calculated = widget.orderTotal * pct / 100;
              fields[cat] = ExtrasField(
                      amount: calculated, percent: pct, usePercent: true)
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
          color: selected
              ? scheme.primary
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppValues.radiusChip),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.3),
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
    barrierDismissible: true,
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
