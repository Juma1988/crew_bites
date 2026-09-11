import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/states/app_settings.dart';
import 'package:app_101/core/theme.dart';
import 'package:app_101/models/order_models.dart';
import 'package:app_101/support/dialog/extras_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await AppSettings.instance.setLocaleCode('en');
  });

  Future<Completer<ExtrasResult?>> openDialog(
    WidgetTester tester, {
    required ExtrasField tip,
  }) async {
    final completer = Completer<ExtrasResult?>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              final result = await showExtrasDialog(
                context,
                initialTip: tip,
                initialDelivery: const ExtrasField(),
                initialTax: const ExtrasField(),
                initialService: const ExtrasField(),
                orderTotal: 100,
              );
              completer.complete(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return completer;
  }

  testWidgets('tip percentage chip updates the saved percentage',
      (tester) async {
    final resultCompleter = await openDialog(
      tester,
      tip: const ExtrasField(amount: 10, percent: 10, usePercent: true),
    );
    await tester.tap(find.text('20%'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final result = await resultCompleter.future;
    expect(result?.allFields[ExtrasCategory.tip]?.usePercent, isTrue);
    expect(result?.allFields[ExtrasCategory.tip]?.percent, 20);
    expect(result?.allFields[ExtrasCategory.tip]?.amount, 20);
  });

  testWidgets('fixed-amount tip mode remains fixed and has no percentage chips',
      (tester) async {
    final resultCompleter = await openDialog(
      tester,
      tip: const ExtrasField(amount: 25),
    );

    expect(find.text('10%'), findsNothing);
    expect(find.text('15%'), findsNothing);
    expect(find.text('20%'), findsNothing);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final result = await resultCompleter.future;
    expect(result?.allFields[ExtrasCategory.tip]?.usePercent, isFalse);
    expect(result?.allFields[ExtrasCategory.tip]?.amount, 25);
  });
}
