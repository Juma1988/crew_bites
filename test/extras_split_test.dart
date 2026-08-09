import 'package:flutter_test/flutter_test.dart';

import 'package:app_101/core/extras_split_mode.dart';
import 'package:app_101/models/order_models.dart';

void main() {
  group('personExtrasShare', () {
    final session = OrderSession(
      id: 's1',
      createdAt: DateTime(2026),
      people: const [
        Person(id: 'me', name: 'Me', colorValue: 0xFF4D96FF),
        Person(id: 'bro', name: 'Bro', colorValue: 0xFFFF6B6B),
      ],
      lines: const [
        OrderLine(id: 'l1', personId: 'me', title: 'A', qty: 1, price: 100),
        OrderLine(id: 'l2', personId: 'bro', title: 'B', qty: 1, price: 50),
      ],
      tipAmount: 30,
      deliveryFee: 0,
    );

    test('default mode splits equally', () {
      expect(session.personExtrasShare('me'), 15);
      expect(session.personExtrasShare('bro'), 15);
    });

    test('byValue splits proportionally to food totals', () {
      expect(
        session.personExtrasShare('me', mode: ExtrasSplitMode.byValue),
        closeTo(20, 1e-9),
      );
      expect(
        session.personExtrasShare('bro', mode: ExtrasSplitMode.byValue),
        closeTo(10, 1e-9),
      );
    });

    test('byValue gives 0 to people with no order', () {
      final s2 = OrderSession(
        id: 's2',
        createdAt: DateTime(2026),
        people: const [
          Person(id: 'a', name: 'A', colorValue: 0xFF4D96FF),
          Person(id: 'b', name: 'B', colorValue: 0xFFFF6B6B),
        ],
        lines: const [
          OrderLine(
              id: 'l1', personId: 'a', title: 'Koshary', qty: 1, price: 40),
        ],
        tipAmount: 12,
      );
      expect(s2.personExtrasShare('a', mode: ExtrasSplitMode.byValue), 12);
      expect(s2.personExtrasShare('b', mode: ExtrasSplitMode.byValue), 0);
    });

    test('byValue falls back to even when nothing is priced', () {
      final s3 = OrderSession(
        id: 's3',
        createdAt: DateTime(2026),
        people: const [
          Person(id: 'a', name: 'A', colorValue: 0xFF4D96FF),
          Person(id: 'b', name: 'B', colorValue: 0xFFFF6B6B),
        ],
        lines: const [
          OrderLine(id: 'l1', personId: 'a', title: 'Free', qty: 1, price: 0),
        ],
        tipAmount: 10,
      );
      expect(s3.personExtrasShare('a', mode: ExtrasSplitMode.byValue), 5);
      expect(s3.personExtrasShare('b', mode: ExtrasSplitMode.byValue), 5);
    });
  });

  group('rounding', () {
    final s = OrderSession(
      id: 'r1',
      createdAt: DateTime(2026),
      people: const [
        Person(id: 'a', name: 'A', colorValue: 0xFF4D96FF),
        Person(id: 'b', name: 'B', colorValue: 0xFFFF6B6B),
        Person(id: 'c', name: 'C', colorValue: 0xFF6BCB77),
        Person(id: 'd', name: 'D', colorValue: 0xFFFFD93D),
      ],
      lines: const [
        OrderLine(id: 'l1', personId: 'a', title: 'A', qty: 1, price: 25),
        OrderLine(id: 'l2', personId: 'b', title: 'B', qty: 1, price: 25),
        OrderLine(id: 'l3', personId: 'c', title: 'C', qty: 1, price: 25),
        OrderLine(id: 'l4', personId: 'd', title: 'D', qty: 1, price: 25),
      ],
      tipAmount: 30,
    );

    test('rounded shares are whole and sum exactly to the extras', () {
      final shares = s.roundedExtrasShares();
      expect(shares.length, 4);
      for (final v in shares.values) {
        expect(v, v.roundToDouble());
      }
      expect(shares.values.fold(0.0, (a, b) => a + b), 30);
    });

    test('rounded grand totals sum exactly to the grand total', () {
      final grand = s.grandTotal; // 100 food + 30 tip = 130
      var sum = 0.0;
      for (final p in s.people) {
        sum += s.personGrandTotalFor(
          p.id,
          mode: ExtrasSplitMode.even,
          round: true,
        );
      }
      expect(sum, grand);
    });

    test('unrounded mode keeps fractional shares', () {
      expect(
        s.personExtrasShareFor('a', mode: ExtrasSplitMode.even, round: false),
        7.5,
      );
    });
  });

  group('percent tip', () {
    final s = OrderSession(
      id: 'p1',
      createdAt: DateTime(2026),
      people: const [
        Person(id: 'a', name: 'A', colorValue: 0xFF4D96FF),
      ],
      lines: const [
        OrderLine(id: 'l1', personId: 'a', title: 'Koshary', qty: 2, price: 50),
      ],
      tipAmount: 5,
      tipPercent: 10,
    );

    test('effectiveTip is a % of the food subtotal when set', () {
      expect(s.orderTotal, 100);
      expect(s.effectiveTip, 10);
      expect(s.grandTotal, 110);
      expect(s.personExtrasShare('a'), closeTo(10, 1e-9));
    });

    test('falls back to the fixed amount when no percent', () {
      final s2 = s.copyWith(tipPercent: null, clearTipPercent: true);
      expect(s2.tipPercent, isNull);
      expect(s2.effectiveTip, 5);
    });

    test('tipPercent survives JSON round trip', () {
      final decoded = OrderSession.decode(s.encode())!;
      expect(decoded.tipPercent, 10);
      expect(decoded.effectiveTip, 10);
    });
  });
}
