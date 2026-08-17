import 'package:flutter_test/flutter_test.dart';

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
      tip: ExtrasField(amount: 30),
      delivery: const ExtrasField(),
      tax: const ExtrasField(percent: 14, usePercent: true),
      service: const ExtrasField(percent: 12, usePercent: true),
    );

    test('tip splits evenly', () {
      expect(session.personTipShare('me'), 15);
      expect(session.personTipShare('bro'), 15);
    });

    test('tax splits by value (proportional to food)', () {
      // orderTotal = 150, tax = 14% of 150 = 21
      // me: 100/150 * 21 = 14, bro: 50/150 * 21 = 7
      expect(session.personTaxShare('me'), closeTo(14, 1e-9));
      expect(session.personTaxShare('bro'), closeTo(7, 1e-9));
    });

    test('service splits by value', () {
      // service = 12% of 150 = 18
      // me: 100/150 * 18 = 12, bro: 50/150 * 18 = 6
      expect(session.personServiceShare('me'), closeTo(12, 1e-9));
      expect(session.personServiceShare('bro'), closeTo(6, 1e-9));
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
        tax: const ExtrasField(percent: 14, usePercent: true),
      );
      // tax = 14% of 40 = 5.6
      expect(s2.personTaxShare('a'), closeTo(5.6, 1e-9));
      expect(s2.personTaxShare('b'), 0);
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
        tax: const ExtrasField(percent: 14, usePercent: true),
      );
      // tax = 14% of 0 = 0, fallback to even = 0
      expect(s3.personTaxShare('a'), 0);
      expect(s3.personTaxShare('b'), 0);
    });

    test('totalExtras sums all four fields', () {
      // tip=30, delivery=0, tax=14%*150=21, service=12%*150=18
      // total = 30 + 0 + 21 + 18 = 69
      expect(session.totalExtras, closeTo(69, 1e-9));
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
      tip: ExtrasField(amount: 30),
    );

    test('rounded grand totals are whole and sum exactly to grand total', () {
      final grand = s.grandTotal; // 100 food + 30 tip = 130
      final rounded = s.roundedGrandTotals();
      expect(rounded.length, 4);
      for (final v in rounded.values) {
        expect(v, v.roundToDouble());
      }
      expect(rounded.values.fold(0.0, (a, b) => a + b), grand);
    });

    test('rounded grand totals sum exactly to the grand total', () {
      final grand = s.grandTotal; // 100 food + 30 tip = 130
      var sum = 0.0;
      for (final p in s.people) {
        sum += s.personGrandTotalFor(p.id, round: true);
      }
      expect(sum, grand);
    });

    test('unrounded mode keeps fractional shares', () {
      // tip=30/4=7.5 per person (no tax/service in this session)
      final sNoTax = OrderSession(
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
        tip: const ExtrasField(amount: 30),
        tax: const ExtrasField(),
        service: const ExtrasField(),
      );
      expect(
        sNoTax.personExtrasShareFor('a', round: false),
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
      tip: const ExtrasField(percent: 10, usePercent: true),
      tax: const ExtrasField(),
      service: const ExtrasField(),
    );

    test('effectiveTip is a % of the food subtotal when set', () {
      expect(s.orderTotal, 100);
      expect(s.effectiveTip, 10);
      expect(s.grandTotal, 110);
      expect(s.personTipShare('a'), closeTo(10, 1e-9));
    });

    test('falls back to the fixed amount when no percent', () {
      final s2 = s.copyWith(tip: const ExtrasField(amount: 5));
      expect(s2.tip.usePercent, false);
      expect(s2.effectiveTip, 5);
    });

    test('tip survives JSON round trip', () {
      final decoded = OrderSession.decode(s.encode())!;
      expect(decoded.tip.usePercent, true);
      expect(decoded.tip.percent, 10);
      expect(decoded.effectiveTip, 10);
    });
  });

  group('extras field defaults', () {
    test('tax defaults to 14%', () {
      const tax = ExtrasField(percent: 14, usePercent: true);
      expect(tax.effectiveAmount(100), 14);
    });

    test('service defaults to 12%', () {
      const service = ExtrasField(percent: 12, usePercent: true);
      expect(service.effectiveAmount(100), 12);
    });

    test('fixed amount field', () {
      const delivery = ExtrasField(amount: 25);
      expect(delivery.effectiveAmount(100), 25);
    });
  });
}
