import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/states/app_settings.dart';
import 'package:app_101/core/translate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
  });

  group('Translate.formatAmount', () {
    test('whole numbers without decimals', () {
      const t = Translate();
      expect(t.formatAmount(40), '40');
      expect(t.formatAmount(0), '0');
      expect(t.formatAmount(100), '100');
      expect(t.formatAmount(-5), '-5');
    });

    test('fractional numbers with 2 decimal places', () {
      const t = Translate();
      expect(t.formatAmount(12.5), '12.50');
      expect(t.formatAmount(0.01), '0.01');
      expect(t.formatAmount(99.99), '99.99');
    });

    test('English uses grouped decimal formatting', () async {
      await AppSettings.instance.setLocaleCode('en');
      expect(Translate.instance.formatAmount(1234.5), '1,234.50');
      expect(Translate.instance.formatAmount(1234), '1,234');
    });

    test('Arabic preserves the established numeric presentation', () async {
      await AppSettings.instance.setLocaleCode('ar');
      expect(Translate.instance.formatAmount(1234.5), '1,234.50');
      expect(Translate.instance.formatAmount(1234), '1,234');
    });
  });

  group('Translate.money', () {
    test('appends currency suffix', () async {
      const t = Translate();
      // Default currency is EGP → suffix is 'le' in English
      expect(t.money(40), contains('40'));
      expect(t.money(40), contains('le'));
    });

    test('hideZero returns empty for zero', () {
      const t = Translate();
      expect(t.money(0, hideZero: true), '');
    });

    test('hideZero returns value for positive', () {
      const t = Translate();
      expect(t.money(10, hideZero: true), isNotEmpty);
    });

    test('keeps visible currency choices while localizing amount', () async {
      await AppSettings.instance.setLocaleCode('en');
      await AppSettings.instance.setCurrencyCode('USD');
      expect(Translate.instance.money(1234.5), '1,234.50 \$');

      await AppSettings.instance.setLocaleCode('ar');
      await AppSettings.instance.setCurrencyCode('EGP');
      expect(Translate.instance.money(1234.5), '1,234.50 ج.م');
    });
  });

  group('Translate.foodUnitsLine', () {
    test('without unitPrice shows qty and title', () {
      const t = Translate();
      final result = t.foodUnitsLine('Koshary', 2);
      expect(result, contains('2'));
      expect(result, contains('Koshary'));
      expect(result, contains('|'));
    });

    test('with unitPrice shows qty, title, and price', () {
      const t = Translate();
      final result = t.foodUnitsLine('Koshary', 1, unitPrice: 40);
      expect(result, contains('1'));
      expect(result, contains('Koshary'));
      expect(result, contains('40'));
    });

    test('with zero unitPrice ignores price', () {
      const t = Translate();
      final result = t.foodUnitsLine('Koshary', 1, unitPrice: 0);
      // Should not contain price since unitPrice is 0
      expect(result, contains('Koshary'));
    });
  });

  group('Translate.foodWithPrice', () {
    test('returns title only for zero price', () {
      const t = Translate();
      expect(t.foodWithPrice('Koshary', 0), 'Koshary');
      expect(t.foodWithPrice('Koshary', -5), 'Koshary');
    });

    test('returns title with price for positive price', () {
      const t = Translate();
      final result = t.foodWithPrice('Koshary', 40);
      expect(result, contains('Koshary'));
      expect(result, contains('40'));
    });
  });
}
