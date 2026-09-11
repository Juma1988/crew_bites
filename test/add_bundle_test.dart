import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/states/app_settings.dart';
import 'package:app_101/core/app_navigator.dart';
import 'package:app_101/core/states/bundles_store.dart';
import 'package:app_101/core/states/order_store.dart';
import 'package:app_101/main.dart';
import 'package:app_101/models/order_models.dart';
import 'package:app_101/models/output_args.dart';
import 'package:app_101/screens/output_history_page.dart';
import 'package:app_101/widgets/summary_onboarding.dart';
import 'package:app_101/widgets/orders_onboarding.dart';
import 'package:app_101/widgets/onboarding_overlay.dart';
import 'package:app_101/models/restaurant_group.dart';
import 'package:app_101/screens/add_orders_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await AppSettings.instance.setLocaleCode('ar');
    await SummaryOnboarding.markDone();
    await OrdersOnboarding.markDone();
    await OnboardingOverlay.markDone();
  });

  testWidgets('adding a new bundle from the food page does not crash',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final session = OrderSession(
      id: 's_test',
      createdAt: now,
      updatedAt: now,
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: const [],
    );
    await OrderStore.saveCurrent(session, prefs);
    await AppSettings.instance.load();

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text('كمّل'));
    await tester.pumpAndSettle();

    final addIcon = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.add_rounded && w.size == 26,
    );
    expect(addIcon, findsWidgets);
    await tester.ensureVisible(addIcon);
    await tester.pumpAndSettle();
    await tester.tap(addIcon, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('باقة جديدة'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'محل جديد');
    await tester.tap(find.text('احفظ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('عدّل'), findsWidgets);
  });

  testWidgets('building a bundle from the summary page does not crash',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final session = OrderSession(
      id: 's_summary',
      createdAt: now,
      updatedAt: now,
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: [
        OrderLine(
            id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 40),
      ],
    );
    await OrderStore.saveCurrent(session, prefs);
    await AppSettings.instance.load();

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final args = OutputHistoryArgs(session: session, fromHistory: true);
    AppNavigator.key.currentState!.pushNamed(
      OutputHistoryPage.route,
      arguments: args,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.playlist_add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.playlist_add_rounded),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('سمّي الباقة'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'باقة كشري');
    await tester.tap(find.text('احفظ'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a bundle applies its saved tip default',
      (tester) async {
    await AppSettings.instance.setLocaleCode('en');
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final session = OrderSession(
      id: 's_tip_default',
      createdAt: now,
      updatedAt: now,
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: const [],
    );
    await OrderStore.saveCurrent(session, prefs);
    await BundlesStore.save([
      const RestaurantGroup(
        id: 'custom_tip',
        nameEn: 'Tip Restaurant',
        nameAr: 'Tip Restaurant',
        items: ['Koshary'],
        colorValue: 0xFF4D96FF,
        defaultTip: ExtrasField(amount: 12),
      ),
    ], prefs);

    await tester.pumpWidget(const App101());
    await tester.pump();
    AppNavigator.key.currentState!.pushNamed(AddOrdersPage.route);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tip Restaurant'));
    await tester.pumpAndSettle();

    final updated = await OrderStore.loadCurrent(prefs);
    expect(updated?.tip.amount, 12);
  });
}
