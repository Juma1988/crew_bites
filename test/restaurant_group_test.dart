import 'package:flutter_test/flutter_test.dart';

import 'package:app_101/models/order_models.dart';
import 'package:app_101/models/restaurant_group.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RestaurantGroup serialization', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final group = RestaurantGroup(
        id: 'custom_1',
        nameEn: 'Food Court',
        nameAr: 'محل أكل',
        emoji: '🍽️',
        colorValue: 0xFF4D96FF,
        items: const ['Koshary', 'Soup'],
        itemPrices: const {'koshary': 40, 'soup': 20},
        defaultTax: const ExtrasField(percent: 14, usePercent: true),
        defaultService: const ExtrasField(percent: 12, usePercent: true),
        defaultDelivery: const ExtrasField(amount: 10),
        isBuiltIn: false,
      );

      final json = group.toJson();
      final decoded = RestaurantGroup.fromJson(json);

      expect(decoded.id, 'custom_1');
      expect(decoded.nameEn, 'Food Court');
      expect(decoded.nameAr, 'محل أكل');
      expect(decoded.emoji, '🍽️');
      expect(decoded.colorValue, 0xFF4D96FF);
      expect(decoded.items, ['Koshary', 'Soup']);
      expect(decoded.itemPrices['koshary'], 40);
      expect(decoded.itemPrices['soup'], 20);
      expect(decoded.defaultTax.percent, 14);
      expect(decoded.defaultTax.usePercent, isTrue);
      expect(decoded.defaultService.percent, 12);
      expect(decoded.defaultDelivery.amount, 10);
      expect(decoded.isBuiltIn, isFalse);
    });

    test('fromJson falls back to name when nameEn is missing', () {
      final json = <String, dynamic>{
        'id': 'legacy',
        'name': 'Legacy Bundle',
        'items': ['A'],
        'isBuiltIn': false,
      };
      final group = RestaurantGroup.fromJson(json);
      expect(group.nameEn, 'Legacy Bundle');
      expect(group.nameAr, 'Legacy Bundle');
    });

    test('fromJson normalizes itemPrices keys to lowercase', () {
      final json = <String, dynamic>{
        'id': 'case',
        'nameEn': 'Test',
        'items': ['Koshary'],
        'itemPrices': {'Koshary': 40, 'SOUP': 20},
        'isBuiltIn': false,
      };
      final group = RestaurantGroup.fromJson(json);
      expect(group.itemPrices.containsKey('koshary'), isTrue);
      expect(group.itemPrices.containsKey('soup'), isTrue);
      expect(group.itemPrices.containsKey('Koshary'), isFalse);
    });

    test('encodeList/decodeList round-trip', () {
      final groups = [
        const RestaurantGroup(
          id: 'g1',
          nameEn: 'A',
          nameAr: 'أ',
          items: ['X'],
          colorValue: 0xFF000001,
          isBuiltIn: true,
        ),
        const RestaurantGroup(
          id: 'g2',
          nameEn: 'B',
          nameAr: 'ب',
          items: ['Y', 'Z'],
          colorValue: 0xFF000002,
          isBuiltIn: false,
          itemPrices: {'y': 10},
        ),
      ];
      final encoded = RestaurantGroup.encodeList(groups);
      final decoded = RestaurantGroup.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].id, 'g1');
      expect(decoded[1].items.length, 2);
      expect(decoded[1].itemPrices['y'], 10);
    });

    test('decodeList returns empty for null/empty/corrupt', () {
      expect(RestaurantGroup.decodeList(null), isEmpty);
      expect(RestaurantGroup.decodeList(''), isEmpty);
      expect(RestaurantGroup.decodeList('NOT JSON'), isEmpty);
    });
  });

  group('RestaurantGroup.migrateId', () {
    test('null/empty maps to freeform', () {
      expect(RestaurantGroup.migrateId(null), RestaurantGroup.freeformId);
      expect(RestaurantGroup.migrateId(''), RestaurantGroup.freeformId);
    });

    test('legacy wemes/wemby maps to wembyId', () {
      expect(RestaurantGroup.migrateId('wemes'), RestaurantGroup.wembyId);
      expect(RestaurantGroup.migrateId('wemby'), RestaurantGroup.wembyId);
    });

    test('legacy al_zaheem/abo_fars maps to aboFarsId', () {
      expect(RestaurantGroup.migrateId('al_zaheem'), RestaurantGroup.aboFarsId);
      expect(RestaurantGroup.migrateId('abo_fars'), RestaurantGroup.aboFarsId);
    });

    test('unknown ids pass through unchanged', () {
      expect(RestaurantGroup.migrateId('custom_1'), 'custom_1');
      expect(RestaurantGroup.migrateId('xyz'), 'xyz');
    });
  });

  test('built-in seeds include starter menus', () {
    final seeds = RestaurantGroup.builtInSeeds();
    final wemby = seeds.firstWhere((g) => g.id == RestaurantGroup.wembyId);
    final aboFars = seeds.firstWhere((g) => g.id == RestaurantGroup.aboFarsId);

    expect(wemby.items, containsAll(['Burger', 'Fries', 'Cola']));
    expect(aboFars.items, containsAll(['Shawarma', 'Falafel', 'Garlic sauce']));
    expect(wemby.isBuiltIn, isTrue);
    expect(aboFars.isBuiltIn, isTrue);
  });

  group('RestaurantGroup.withItemPrices', () {
    test('merges prices for existing items only', () {
      final group = const RestaurantGroup(
        id: 'g',
        nameEn: 'Test',
        nameAr: 'Test',
        items: ['Koshary', 'Soup'],
        colorValue: 0xFF000000,
        itemPrices: {},
      );
      final updated = group.withItemPrices({
        'koshary': 40,
        'fries': 15, // not in items
      });
      expect(updated.itemPrices['koshary'], 40);
      expect(updated.itemPrices.containsKey('fries'), isFalse);
    });

    test('skips zero/negative prices', () {
      final group = const RestaurantGroup(
        id: 'g',
        nameEn: 'Test',
        nameAr: 'Test',
        items: ['Koshary'],
        colorValue: 0xFF000000,
      );
      final updated = group.withItemPrices({'koshary': 0});
      expect(updated.itemPrices.containsKey('koshary'), isFalse);
    });

    test('returns same instance when no changes', () {
      final group = const RestaurantGroup(
        id: 'g',
        nameEn: 'Test',
        nameAr: 'Test',
        items: ['Koshary'],
        colorValue: 0xFF000000,
        itemPrices: {'koshary': 40},
      );
      final updated = group.withItemPrices({'koshary': 40});
      expect(identical(updated, group), isTrue);
    });
  });

  group('RestaurantGroup.priceForItem', () {
    test('returns price for known item, 0 for unknown', () {
      final group = const RestaurantGroup(
        id: 'g',
        nameEn: 'Test',
        nameAr: 'Test',
        items: [],
        colorValue: 0xFF000000,
        itemPrices: {'koshary': 40},
      );
      expect(group.priceForItem('Koshary'), 40);
      expect(group.priceForItem('koshary'), 40);
      expect(group.priceForItem('soup'), 0);
    });
  });

  group('ExtrasField', () {
    test('toJson/fromJson round-trip with percent', () {
      const field = ExtrasField(amount: 10, percent: 14, usePercent: true);
      final json = field.toJson();
      final decoded = ExtrasField.fromJson(json);
      expect(decoded.amount, 10);
      expect(decoded.percent, 14);
      expect(decoded.usePercent, isTrue);
    });

    test('toJson/fromJson round-trip with fixed amount', () {
      const field = ExtrasField(amount: 25);
      final json = field.toJson();
      final decoded = ExtrasField.fromJson(json);
      expect(decoded.amount, 25);
      expect(decoded.percent, isNull);
      expect(decoded.usePercent, isFalse);
    });

    test('hasValue returns true when usePercent with valid percent', () {
      expect(const ExtrasField(percent: 14, usePercent: true).hasValue, isTrue);
      expect(const ExtrasField(percent: 0, usePercent: true).hasValue, isFalse);
      expect(
          const ExtrasField(percent: null, usePercent: true).hasValue, isFalse);
    });

    test('hasValue returns true when fixed amount > 0', () {
      expect(const ExtrasField(amount: 10).hasValue, isTrue);
      expect(const ExtrasField(amount: 0).hasValue, isFalse);
    });

    test('copyWith clearPercent removes percent', () {
      const field = ExtrasField(amount: 10, percent: 14, usePercent: true);
      final cleared = field.copyWith(clearPercent: true);
      expect(cleared.percent, isNull);
      expect(cleared.amount, 10);
    });
  });
}
