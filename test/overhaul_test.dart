import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/friend_icon_style.dart';
import 'package:app_101/core/app_navigator.dart';
import 'package:app_101/core/states/app_settings.dart';
import 'package:app_101/core/states/crew_store.dart';
import 'package:app_101/core/states/order_store.dart';
import 'package:app_101/core/translate.dart';
import 'package:app_101/core/values/app_values.dart';
import 'package:app_101/main.dart';
import 'package:app_101/models/order_models.dart';
import 'package:app_101/models/output_args.dart';
import 'package:app_101/models/restaurant_group.dart';
import 'package:app_101/screens/add_orders_page.dart';
import 'package:app_101/screens/add_user_page.dart';
import 'package:app_101/screens/output_history_page.dart';
import 'package:app_101/screens/settings_page.dart';
import 'package:app_101/widgets/summary_onboarding.dart';
import 'package:app_101/widgets/orders_onboarding.dart';
import 'package:app_101/widgets/onboarding_overlay.dart';

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

  test('share line format is amount-first with no price', () {
    final t = Translate.instance;
    expect(t.foodUnitsLine('فول صلصة', 1), '1 | فول صلصة');
    expect(t.foodUnitsLine('فول صلصة', 2), '2 | فول صلصة');
  });

  test('bundle names are title-cased for display only', () {
    final group = RestaurantGroup(
      id: 'custom_1',
      nameEn: 'food court',
      nameAr: 'محل جديد',
      emoji: '🍽️',
      colorValue: 0xFF4D96FF,
      items: const ['Koshary'],
      isBuiltIn: false,
    );
    expect(RestaurantGroup.titleCaseNameOf('food court'), 'Food Court');
    expect(RestaurantGroup.titleCaseNameOf('محل جديد'), 'محل جديد');
    expect(group.titleCaseName, 'Food Court');
    expect(group.displayName(arabic: false), 'Food Court');
    expect(group.displayName(arabic: true), 'محل جديد');
  });

  test('friend icon marks follow the selected style', () {
    final p =
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF);
    expect(friendIconMark(p, FriendIconStyle.emoji, 0), '😎');
    expect(friendIconMark(p, FriendIconStyle.roman, 0), 'I');
    expect(friendIconMark(p, FriendIconStyle.roman, 2), 'III');
    expect(friendIconMark(p, FriendIconStyle.firstLetter, 0), 'A');
    expect(friendIconMark(p, FriendIconStyle.firstTwo, 0), 'AL');
    expect(friendUsesEmoji(p, FriendIconStyle.roman), isFalse);
    expect(friendUsesEmoji(p, FriendIconStyle.emoji), isTrue);
  });

  testWidgets('Done & save saves directly with a Saved snackbar (no dialog)',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final session = OrderSession(
      id: 's_done',
      createdAt: now,
      updatedAt: now,
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: [
        OrderLine(id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 0),
      ],
    );
    await OrderStore.saveCurrent(session, prefs);

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final args = OutputHistoryArgs(session: session, fromHistory: false);
    AppNavigator.key.currentState!.pushNamed(
      OutputHistoryPage.route,
      arguments: args,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('خلص واحفظ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خلص واحفظ'));
    // Pump through snackbar + navigation to HomePage (enter animation).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    // No confirm dialog.
    expect(find.text('أنهي الطلب ده؟'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('تم الحفظ ✓'), findsOneWidget);
  });

  testWidgets('summary paid control updates and persists the current session',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final session = OrderSession(
      id: 's_paid_toggle',
      createdAt: now,
      people: const [Person(id: 'p1', name: 'Ali', colorValue: 0xFF000000)],
      lines: const [
        OrderLine(id: 'l1', personId: 'p1', title: 'Koshary'),
      ],
    );
    await OrderStore.saveCurrent(session, prefs);

    await tester.pumpWidget(const App101());
    await tester.pumpAndSettle();
    AppNavigator.key.currentState!.pushNamed(
      OutputHistoryPage.route,
      arguments: OutputHistoryArgs(session: session),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('علّم إنه دفع. دوس مرتين على الكارت للتغيير'),
        findsOneWidget);
    await tester.tap(find.text('Ali').first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Ali').first);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byTooltip('دفع. دوس مرتين على الكارت للتغيير'),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('دفع. دوس مرتين على الكارت للتغيير'), findsOneWidget);
    expect((await OrderStore.loadCurrent(prefs))?.isPersonPaid('p1'), isTrue);
  });

  testWidgets('settings accordion expands one section on a single tap',
      (tester) async {
    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    AppNavigator.key.currentState!.pushNamed(SettingsPage.route);
    await tester.pumpAndSettle();

    // Help section is collapsed at first — step titles should not be visible.
    expect(find.text('1'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('مساعدة'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('مساعدة'));
    await tester.pumpAndSettle();

    // Help section expanded — step titles should now be visible.
    expect(find.text('1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('friends screen draws the friend icon style on avatars',
      (tester) async {
    await AppSettings.instance.setFriendIconStyle(FriendIconStyle.roman);
    // Seed some names into the roster so Roman numeral labels appear.
    await CrewStore.instance
        .addPerson(name: 'Alex', colorValue: 0xFF4D96FF, emoji: '😎');
    await CrewStore.instance
        .addPerson(name: 'Sam', colorValue: 0xFFFF6B6B, emoji: '🙂');

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    AppNavigator.key.currentState!.pushNamed(AddUserPage.route);
    await tester.pumpAndSettle();

    // Alex → roman I, Sam → roman II.
    expect(find.text('I'), findsWidgets);
    expect(find.text('II'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('services row only appears on the summary when prices are on',
      (tester) async {
    final now = DateTime.now();
    final session = OrderSession(
      id: 's_services',
      createdAt: now,
      updatedAt: now,
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: [
        OrderLine(
            id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 40),
      ],
      tip: const ExtrasField(amount: 12),
    );

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final args = OutputHistoryArgs(session: session, fromHistory: true);
    AppNavigator.key.currentState!.pushNamed(
      OutputHistoryPage.route,
      arguments: args,
    );
    await tester.pumpAndSettle();

    // Explicitly turn prices OFF first.
    await AppSettings.instance.setPricesEnabled(false);
    await tester.pumpAndSettle();

    // Prices off → no extras rows.
    expect(find.text('نصيبك'), findsNothing);

    await AppSettings.instance.setPricesEnabled(true);
    await tester.pumpAndSettle();

    // Session has only tip=12 → extras share row shows 'نصيبك'
    expect(find.text('نصيبك'), findsWidgets);
  });

  testWidgets('bundle pill shows a food emoji and title-cases the name',
      (tester) async {
    await AppSettings.instance.setLocaleCode('en');
    final prefs = await SharedPreferences.getInstance();
    final group = RestaurantGroup(
      id: 'custom_pill',
      nameEn: 'food court',
      nameAr: 'food court',
      emoji: '🍽️',
      colorValue: 0xFF4D96FF,
      items: const ['Koshary'],
      isBuiltIn: false,
    );
    await prefs.setString(
      AppValues.prefsRestaurantGroups,
      RestaurantGroup.encodeList([group]),
    );

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    AppNavigator.key.currentState!.pushNamed(AddOrdersPage.route);
    await tester.pumpAndSettle();

    expect(find.text('Food Court'), findsWidgets);
    expect(find.text('🍽️'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bundle editor saves the last typed item when Done is tapped',
      (tester) async {
    await AppSettings.instance.setLocaleCode('en');
    final prefs = await SharedPreferences.getInstance();
    final group = RestaurantGroup(
      id: 'custom_done',
      nameEn: 'food court',
      nameAr: 'food court',
      emoji: '🍽️',
      colorValue: 0xFF4D96FF,
      items: const ['Koshary'],
      isBuiltIn: false,
    );
    await prefs.setString(
      AppValues.prefsRestaurantGroups,
      RestaurantGroup.encodeList([group]),
    );

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    AppNavigator.key.currentState!.pushNamed(AddOrdersPage.route);
    await tester.pumpAndSettle();

    // Open the editor, type a second item, and tap Done WITHOUT pressing +.
    await tester.longPress(find.text('Food Court'));
    await tester.pumpAndSettle();
    final sheetField = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(sheetField, 'Soup');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Reopen the editor: the typed item must have been committed.
    await tester.longPress(find.text('Food Court'));
    await tester.pumpAndSettle();
    expect(find.text('Soup'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary shows Create bundle icon for a no-bundle order',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final session = OrderSession(
      id: 's_create',
      createdAt: now,
      updatedAt: now,
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: [
        OrderLine(id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 0),
      ],
    );
    await OrderStore.saveCurrent(session, prefs);

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
    expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.update_rounded), findsNothing);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary shows Update bundle icon when a new item was added',
      (tester) async {
    await AppSettings.instance.setLocaleCode('en');
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final group = RestaurantGroup(
      id: 'custom_upd',
      nameEn: 'Food Court',
      nameAr: 'Food Court',
      emoji: '🍽️',
      colorValue: 0xFF4D96FF,
      items: const ['Koshary'],
      isBuiltIn: false,
    );
    await prefs.setString(
      AppValues.prefsRestaurantGroups,
      RestaurantGroup.encodeList([group]),
    );
    final session = OrderSession(
      id: 's_upd',
      createdAt: now,
      updatedAt: now,
      groupId: 'custom_upd',
      groupName: 'Food Court',
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: [
        OrderLine(
            id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 40),
        OrderLine(id: 'l2', personId: 'p1', title: 'Soup', qty: 1, price: 20),
      ],
    );
    await OrderStore.saveCurrent(session, prefs);

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final args = OutputHistoryArgs(session: session, fromHistory: true);
    AppNavigator.key.currentState!.pushNamed(
      OutputHistoryPage.route,
      arguments: args,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.update_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.update_rounded), findsOneWidget);
    expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary hides bundle icons when the order matches the bundle',
      (tester) async {
    await AppSettings.instance.setLocaleCode('en');
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final group = RestaurantGroup(
      id: 'custom_match',
      nameEn: 'Food Court',
      nameAr: 'Food Court',
      emoji: '🍽️',
      colorValue: 0xFF4D96FF,
      items: const ['Koshary'],
      isBuiltIn: false,
    );
    await prefs.setString(
      AppValues.prefsRestaurantGroups,
      RestaurantGroup.encodeList([group]),
    );
    final session = OrderSession(
      id: 's_match',
      createdAt: now,
      updatedAt: now,
      groupId: 'custom_match',
      groupName: 'Food Court',
      people: const [
        Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
      lines: [
        OrderLine(
            id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 40),
      ],
    );
    await OrderStore.saveCurrent(session, prefs);

    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final args = OutputHistoryArgs(session: session, fromHistory: true);
    AppNavigator.key.currentState!.pushNamed(
      OutputHistoryPage.route,
      arguments: args,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.update_rounded), findsNothing);
    expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
