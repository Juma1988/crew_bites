import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/states/app_settings.dart';
import 'package:app_101/core/theme.dart';
import 'package:app_101/core/translate.dart';
import 'package:app_101/app.dart';
import 'package:app_101/models/order_models.dart';
import 'package:app_101/models/output_args.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await AppSettings.instance.setLocaleCode('ar');
  });

  testWidgets('app opens Crew Bites Home (default Arabic)', (tester) async {
    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text(AppTheme.brandName), findsWidgets);
    // Default locale is Egyptian Arabic.
    expect(find.textContaining('مين'), findsWidgets);
  });

  testWidgets('app opens Crew Bites Home in English when set', (tester) async {
    await AppSettings.instance.setLocaleCode('en');
    await tester.pumpWidget(const App101());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text(AppTheme.brandName), findsWidgets);
    expect(find.textContaining('Who'), findsWidgets);
  });

  test('foodWithPrice hides zero amount noise', () {
    final t = Translate.instance;
    expect(t.foodWithPrice('Pizza', 0), 'Pizza');
    expect(t.foodWithPrice('Pizza', 12), contains('Pizza'));
    expect(t.foodWithPrice('Pizza', 12), contains('12'));
  });

  test('OutputHistoryArgs carries history session', () {
    final s = OrderSession.empty().copyWith(
      people: const [
        Person(id: '1', name: 'A', emoji: '😎', colorValue: 0xFF4D96FF),
      ],
    );
    final args = OutputHistoryArgs(session: s, fromHistory: true);
    expect(args.fromHistory, isTrue);
    expect(args.session?.people.first.name, 'A');
  });

  test('currency suffixes change with settings + locale', () async {
    await AppSettings.instance.setLocaleCode('en');
    await AppSettings.instance.setCurrencyCode('USD');
    expect(Translate.instance.currencySuffix, r'$');
    await AppSettings.instance.setCurrencyCode('EGP');
    expect(Translate.instance.currencySuffix, 'le');

    await AppSettings.instance.setLocaleCode('ar');
    expect(Translate.instance.currencySuffix, 'ج.م');
  });
}
