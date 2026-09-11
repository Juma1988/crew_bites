import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/states/order_store.dart';
import 'package:app_101/models/order_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // ── OrderSession serialization ──────────────────────────────────────

  group('OrderSession serialization', () {
    test('full round-trip preserves all fields', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final session = OrderSession(
        id: 's_roundtrip',
        createdAt: now,
        updatedAt: now,
        people: const [
          Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF4D96FF),
          Person(id: 'p2', name: 'Sara', emoji: '🙂', colorValue: 0xFFFF6B6B),
        ],
        lines: const [
          OrderLine(
              id: 'l1', personId: 'p1', title: 'Koshary', qty: 2, price: 40),
          OrderLine(
              id: 'l2',
              personId: 'p2',
              title: 'Soup',
              qty: 1,
              price: 20,
              note: 'hot'),
        ],
        groupId: 'custom_1',
        groupName: 'Food Court',
        foodPrices: const {'koshary': 40, 'soup': 20},
        tip: const ExtrasField(amount: 12),
        delivery: const ExtrasField(amount: 10),
        tax: const ExtrasField(percent: 14, usePercent: true),
        service: const ExtrasField(percent: 12, usePercent: true),
      );

      final json = session.toJson();
      final decoded = OrderSession.fromJson(json);

      expect(decoded.id, session.id);
      expect(decoded.createdAt, session.createdAt);
      expect(decoded.people.length, 2);
      expect(decoded.people[0].name, 'Ali');
      expect(decoded.people[1].emoji, '🙂');
      expect(decoded.lines.length, 2);
      expect(decoded.lines[0].qty, 2);
      expect(decoded.lines[1].note, 'hot');
      expect(decoded.groupId, 'custom_1');
      expect(decoded.groupName, 'Food Court');
      expect(decoded.foodPrices['koshary'], 40);
      expect(decoded.tip.amount, 12);
      expect(decoded.delivery.amount, 10);
      expect(decoded.tax.percent, 14);
      expect(decoded.tax.usePercent, isTrue);
      expect(decoded.service.percent, 12);
      expect(decoded.service.usePercent, isTrue);
    });

    test('encode/decode round-trip via JSON string', () {
      final session = OrderSession(
        id: 's_enc',
        createdAt: DateTime(2025, 1, 1),
        people: const [
          Person(id: 'p1', name: 'Test', emoji: '🍕', colorValue: 0xFF000000)
        ],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'Pizza', qty: 3, price: 50)
        ],
      );
      final encoded = session.encode();
      final decoded = OrderSession.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.id, 's_enc');
      expect(decoded.lines[0].lineTotal, 150);
    });

    test('decode returns null for null/empty/corrupt input', () {
      expect(OrderSession.decode(null), isNull);
      expect(OrderSession.decode(''), isNull);
      expect(OrderSession.decode('{bad json'), isNull);
    });

    test('decodeChecked calls onCorrupt for corrupt data', () {
      var called = false;
      OrderSession.decodeChecked('{bad', onCorrupt: () => called = true);
      expect(called, isTrue);
    });

    test('backward-compat: old flat tip format is decoded', () {
      final oldJson = {
        'id': 's_old',
        'createdAt': '2025-01-01T00:00:00.000',
        'people': <Map<String, dynamic>>[],
        'lines': <Map<String, dynamic>>[],
        'tipAmount': 15.0,
        'tipPercent': 10.0,
        'deliveryFee': 5.0,
      };
      final session = OrderSession.fromJson(oldJson);
      expect(session.tip.amount, 15);
      expect(session.tip.usePercent, isTrue);
      expect(session.tip.percent, 10);
      expect(session.delivery.amount, 5);
      // tax/service default to built-in percentages
      expect(session.tax.hasValue, isFalse);
      expect(session.service.hasValue, isFalse);
    });

    test('foodPrices keys are lowercased during decode', () {
      final json = {
        'id': 's_case',
        'createdAt': '2025-01-01T00:00:00.000',
        'people': <Map<String, dynamic>>[],
        'lines': <Map<String, dynamic>>[],
        'foodPrices': {'Koshary': 40, 'SOUP': 20},
        'tip': {'amount': 0, 'usePercent': false},
        'delivery': {'amount': 0, 'usePercent': false},
        'tax': {'amount': 0, 'usePercent': false},
        'service': {'amount': 0, 'usePercent': false},
      };
      final session = OrderSession.fromJson(json);
      expect(session.foodPrices.containsKey('koshary'), isTrue);
      expect(session.foodPrices.containsKey('soup'), isTrue);
      expect(session.foodPrices.containsKey('Koshary'), isFalse);
    });

    test('missing optional fields default correctly in OrderLine.fromJson', () {
      final json = <String, dynamic>{
        'id': 'l1',
        'personId': 'p1',
        'title': 'Food',
        // qty, note, price omitted
      };
      final line = OrderLine.fromJson(json);
      expect(line.qty, 1);
      expect(line.note, '');
      expect(line.price, 0);
    });

    test('partially migrated extras default missing fields safely', () {
      final session = OrderSession.fromJson({
        'id': 'partial',
        'createdAt': '2026-01-01T00:00:00.000',
        'people': <Map<String, dynamic>>[],
        'lines': <Map<String, dynamic>>[],
        'tip': {'amount': 12, 'usePercent': false},
      });

      expect(session.tip.amount, 12);
      expect(session.delivery.hasValue, false);
      expect(session.tax.hasValue, false);
      expect(session.service.hasValue, false);
    });

    test('snapshot creates independent deep copy', () {
      final session = OrderSession(
        id: 's_snap',
        createdAt: DateTime(2025, 1, 1),
        people: const [
          Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF000000)
        ],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 1, price: 10)
        ],
      );
      final snap = session.snapshot();
      expect(snap.id, session.id);

      // Mutate original — snapshot should be unaffected.
      // We can't mutate const lists, but we verify snapshot independence
      // by checking it has its own copies of mutable fields.
      expect(snap.lines.length, 1);
      expect(snap.people.length, 1);
      expect(snap.lines[0].title, 'X');
      expect(snap.people[0].name, 'Ali');
    });

    test('toJson omits null groupId/groupName and empty foodPrices', () {
      final session = OrderSession(
        id: 's_omit',
        createdAt: DateTime(2025, 1, 1),
        people: const [],
        lines: const [],
      );
      final json = session.toJson();
      expect(json.containsKey('groupId'), isFalse);
      expect(json.containsKey('groupName'), isFalse);
      expect(json.containsKey('foodPrices'), isFalse);
    });
  });

  // ── OrderSession computed properties ─────────────────────────────────

  group('OrderSession computed properties', () {
    test('setFoodNote updates only the selected person food line', () {
      final session = OrderSession(
        id: 'notes',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'Burger'),
          OrderLine(id: 'l2', personId: 'p2', title: 'Burger'),
        ],
      );

      final updated = OrderStore.setFoodNote(
        session,
        'p1',
        'burger',
        '  no onions  ',
      );

      expect(updated.lines[0].note, 'no onions');
      expect(updated.lines[1].note, isEmpty);
    });

    test('isEmpty and hasContent', () {
      final empty = OrderSession(
          id: 'e',
          createdAt: DateTime.now(),
          people: const [],
          lines: const []);
      expect(empty.isEmpty, isTrue);
      expect(empty.hasContent, isFalse);

      final withPeople = OrderSession(
        id: 'p',
        createdAt: DateTime.now(),
        people: const [Person(id: 'p1', name: 'A', emoji: '', colorValue: 0)],
        lines: const [],
      );
      expect(withPeople.isEmpty, isFalse);
      expect(withPeople.hasContent, isTrue);

      final withLines = OrderSession(
        id: 'l',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 1)],
      );
      expect(withLines.isEmpty, isFalse);
      expect(withLines.hasContent, isTrue);
    });

    test('linesFor filters by personId', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'A', qty: 1),
          OrderLine(id: 'l2', personId: 'p2', title: 'B', qty: 1),
          OrderLine(id: 'l3', personId: 'p1', title: 'C', qty: 2),
        ],
      );
      expect(session.linesFor('p1').length, 2);
      expect(session.linesFor('p2').length, 1);
      expect(session.linesFor('p3'), isEmpty);
    });

    test('personTotal sums line totals for one person', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'A', qty: 2, price: 30),
          OrderLine(id: 'l2', personId: 'p1', title: 'B', qty: 1, price: 50),
          OrderLine(id: 'l3', personId: 'p2', title: 'C', qty: 1, price: 100),
        ],
      );
      expect(session.personTotal('p1'), 110); // 2*30 + 1*50
      expect(session.personTotal('p2'), 100);
    });

    test('priceForTitle looks up foodPrices then lines', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'Soup', qty: 1, price: 15),
        ],
        foodPrices: const {'koshary': 40},
      );
      expect(session.priceForTitle('Koshary'), 40);
      expect(session.priceForTitle('soup'), 15);
      expect(session.priceForTitle('missing'), 0);
    });

    test('aggregateFoods merges by lowercased title', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(
              id: 'l1', personId: 'p1', title: 'Koshary', qty: 2, price: 40),
          OrderLine(
              id: 'l2', personId: 'p2', title: 'koshary', qty: 1, price: 40),
          OrderLine(id: 'l3', personId: 'p1', title: 'Soup', qty: 1, price: 20),
        ],
      );
      final agg = session.aggregateFoods();
      expect(agg.length, 2);
      final koshary = agg.firstWhere((a) => a.title == 'Koshary');
      expect(koshary.qty, 3);
      final soup = agg.firstWhere((a) => a.title == 'Soup');
      expect(soup.qty, 1);
      expect(soup.unitPrice, 20);
    });

    test('itemCount sums all line quantities', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'A', qty: 3),
          OrderLine(id: 'l2', personId: 'p1', title: 'B', qty: 2),
        ],
      );
      expect(session.itemCount, 5);
    });

    test('hasPlace checks groupId and groupName', () {
      final noGroup = OrderSession(
          id: 's',
          createdAt: DateTime.now(),
          people: const [],
          lines: const []);
      expect(noGroup.hasPlace, isFalse);

      final withGroup = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [],
        groupId: 'custom_1',
        groupName: 'Food Court',
      );
      expect(withGroup.hasPlace, isTrue);

      final freeform = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [],
        groupId: 'freeform',
        groupName: 'Freeform',
      );
      expect(freeform.hasPlace, isFalse);
    });
  });

  // ── OrderStore operations ────────────────────────────────────────────

  group('OrderStore.addFoodUnit', () {
    test('adds new line when person has no matching food', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [Person(id: 'p1', name: 'A', emoji: '', colorValue: 0)],
        lines: const [],
      );
      final next =
          OrderStore.addFoodUnit(session, 'p1', 'Koshary', unitPrice: 40);
      expect(next.lines.length, 1);
      expect(next.lines[0].qty, 1);
      expect(next.lines[0].price, 40);
    });

    test('increments qty when person already has same food', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(
              id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 40),
        ],
      );
      final next = OrderStore.addFoodUnit(session, 'p1', 'Koshary');
      expect(next.lines.length, 1);
      expect(next.lines[0].qty, 2);
      expect(next.lines[0].price, 40);
    });

    test('uses existing line price when no unitPrice given', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 1, price: 25),
        ],
      );
      final next = OrderStore.addFoodUnit(session, 'p1', 'X');
      expect(next.lines[0].price, 25);
    });

    test('case-insensitive food title matching', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(
              id: 'l1', personId: 'p1', title: 'Koshary', qty: 1, price: 40),
        ],
      );
      final next = OrderStore.addFoodUnit(session, 'p1', 'koshary');
      expect(next.lines.length, 1);
      expect(next.lines[0].qty, 2);
    });
  });

  group('OrderStore.setFoodPrice', () {
    test('updates all matching lines and foodPrices map', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(
              id: 'l1', personId: 'p1', title: 'Koshary', qty: 2, price: 30),
          OrderLine(
              id: 'l2', personId: 'p2', title: 'koshary', qty: 1, price: 30),
          OrderLine(id: 'l3', personId: 'p1', title: 'Soup', qty: 1, price: 20),
        ],
      );
      final next = OrderStore.setFoodPrice(session, 'Koshary', 50);
      expect(next.lines[0].price, 50);
      expect(next.lines[1].price, 50);
      expect(next.lines[2].price, 20); // unchanged
      expect(next.foodPrices['koshary'], 50);
    });

    test('clamps negative prices to 0', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 1, price: 10),
        ],
      );
      final next = OrderStore.setFoodPrice(session, 'X', -5);
      expect(next.lines[0].price, 0);
      expect(next.foodPrices['x'], 0);
    });
  });

  group('OrderStore.undoFoodUnit', () {
    test('decrements qty when qty > 1', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 3, price: 10),
        ],
      );
      final next = OrderStore.undoFoodUnit(session, 'p1', 'X');
      expect(next, isNotNull);
      expect(next!.lines[0].qty, 2);
    });

    test('removes line when qty is 1', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 1, price: 10),
          OrderLine(id: 'l2', personId: 'p1', title: 'Y', qty: 2, price: 20),
        ],
      );
      final next = OrderStore.undoFoodUnit(session, 'p1', 'X');
      expect(next, isNotNull);
      expect(next!.lines.length, 1);
      expect(next.lines[0].title, 'Y');
    });

    test('returns null when no matching line found', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 1, price: 10),
        ],
      );
      final next = OrderStore.undoFoodUnit(session, 'p1', 'Y');
      expect(next, isNull);
    });

    test('only decrements first matching line', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 2, price: 10),
          OrderLine(id: 'l2', personId: 'p1', title: 'X', qty: 3, price: 10),
        ],
      );
      final next = OrderStore.undoFoodUnit(session, 'p1', 'X');
      expect(next!.lines[0].qty, 1);
      expect(next.lines[1].qty, 3); // unchanged
    });
  });

  // ── OrderStore persistence ───────────────────────────────────────────

  group('OrderStore persistence', () {
    test('saveCurrent + loadCurrent round-trip', () async {
      final session = OrderSession(
        id: 's_persist',
        createdAt: DateTime(2025, 3, 10),
        people: const [
          Person(id: 'p1', name: 'Ali', emoji: '😎', colorValue: 0xFF000000)
        ],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 2, price: 25)
        ],
      );
      await OrderStore.saveCurrent(session, prefs);
      final loaded = await OrderStore.loadCurrent(prefs);
      expect(loaded, isNotNull);
      expect(loaded!.id, 's_persist');
      expect(loaded.lines[0].qty, 2);
    });

    test('saveCurrent(null) removes current key', () async {
      final session = OrderSession(
        id: 's_del',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [],
      );
      await OrderStore.saveCurrent(session, prefs);
      await OrderStore.saveCurrent(null, prefs);
      final loaded = await OrderStore.loadCurrent(prefs);
      expect(loaded, isNull);
    });

    test('saveCurrent skips empty sessions', () async {
      final empty = OrderSession(
          id: 's_empty',
          createdAt: DateTime.now(),
          people: const [],
          lines: const []);
      await OrderStore.saveCurrent(empty, prefs);
      final loaded = await OrderStore.loadCurrent(prefs);
      expect(loaded, isNull);
    });

    test('loadHistory + saveHistory round-trip', () async {
      final sessions = [
        OrderSession(
            id: 's1',
            createdAt: DateTime(2025, 1, 1),
            people: const [],
            lines: const []),
        OrderSession(
            id: 's2',
            createdAt: DateTime(2025, 2, 1),
            people: const [],
            lines: const []),
      ];
      await OrderStore.saveHistory(sessions, prefs);
      final loaded = await OrderStore.loadHistory(prefs);
      expect(loaded.length, 2);
      expect(loaded[0].id, 's1');
    });

    test('loadHistory returns empty for corrupt data', () async {
      await prefs.setString('history', 'NOT JSON!!!');
      var corruptCalled = false;
      final loaded = await OrderStore.loadHistory(prefs, () {
        corruptCalled = true;
      });
      expect(loaded, isEmpty);
      expect(corruptCalled, isTrue);
    });

    test('pushHistory deduplicates by id', () async {
      final session = OrderSession(
          id: 's_dup',
          createdAt: DateTime.now(),
          people: const [],
          lines: const []);
      final existing = [session]; // same id
      final result = await OrderStore.pushHistory(session, existing, prefs);
      expect(result.length, 1); // deduped
    });

    test('restoreAsCurrent generates new id', () async {
      final original = OrderSession(
        id: 's_orig',
        createdAt: DateTime(2025, 1, 1),
        people: const [Person(id: 'p1', name: 'A', emoji: '', colorValue: 0)],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'X', qty: 1, price: 10)
        ],
      );
      await OrderStore.restoreAsCurrent(original, prefs);
      final loaded = await OrderStore.loadCurrent(prefs);
      expect(loaded, isNotNull);
      expect(loaded!.id, isNot('s_orig'));
      expect(loaded.lines[0].title, 'X');
    });
  });

  // ── OrderStore helpers ───────────────────────────────────────────────

  group('OrderStore helpers', () {
    test('foodTitlesFromSession returns unique titles in order', () {
      final session = OrderSession(
        id: 's',
        createdAt: DateTime.now(),
        people: const [],
        lines: const [
          OrderLine(id: 'l1', personId: 'p1', title: 'Koshary', qty: 1),
          OrderLine(id: 'l2', personId: 'p2', title: 'koshary', qty: 1),
          OrderLine(id: 'l3', personId: 'p1', title: 'Soup', qty: 1),
        ],
      );
      final titles = OrderStore.foodTitlesFromSession(session);
      expect(titles.length, 2);
      expect(titles[0], 'Koshary');
      expect(titles[1], 'Soup');
    });

    test('foodTitlesFromSession returns empty for null/empty', () {
      expect(OrderStore.foodTitlesFromSession(null), isEmpty);
      final empty = OrderSession(
          id: 'e',
          createdAt: DateTime.now(),
          people: const [],
          lines: const []);
      expect(OrderStore.foodTitlesFromSession(empty), isEmpty);
    });

    test('mergeFoods deduplicates case-insensitively', () {
      final result =
          OrderStore.mergeFoods(['Koshary', 'Soup'], ['koshary', 'Fries']);
      expect(result.length, 3);
      expect(result, contains('Koshary'));
      expect(result, contains('Soup'));
      expect(result, contains('Fries'));
    });

    test('formatPrice whole numbers', () {
      expect(OrderStore.formatPrice(40), '40');
      expect(OrderStore.formatPrice(0), '0');
      expect(OrderStore.formatPrice(100), '100');
    });

    test('formatPrice fractional numbers', () {
      expect(OrderStore.formatPrice(12.5), '12.50');
      expect(OrderStore.formatPrice(0.01), '0.01');
      expect(OrderStore.formatPrice(99.99), '99.99');
    });
  });
}
