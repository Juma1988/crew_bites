import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/states/bundles_store.dart';
import 'package:app_101/models/order_models.dart';
import 'package:app_101/models/restaurant_group.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('built-in bundle migration preserves saved extras including tip',
      () async {
    SharedPreferences.setMockInitialValues({
      'restaurant_groups': RestaurantGroup.encodeList([
        const RestaurantGroup(
          id: 'wemes',
          nameEn: 'Legacy Wemby',
          nameAr: 'قديم',
          items: ['Burger'],
          colorValue: 0xFF000000,
          defaultTax: ExtrasField(amount: 2),
          defaultService: ExtrasField(amount: 3),
          defaultDelivery: ExtrasField(amount: 4),
          defaultTip: ExtrasField(amount: 5),
        ),
      ]),
    });

    final prefs = await SharedPreferences.getInstance();
    final groups = await BundlesStore.load(prefs);
    final wemby = groups.firstWhere((g) => g.id == RestaurantGroup.wembyId);

    expect(wemby.defaultTax.amount, 2);
    expect(wemby.defaultService.amount, 3);
    expect(wemby.defaultDelivery.amount, 4);
    expect(wemby.defaultTip.amount, 5);
  });
}
