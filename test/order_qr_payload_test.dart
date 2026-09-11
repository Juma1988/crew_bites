import 'package:flutter_test/flutter_test.dart';

import 'package:app_101/core/order_qr_payload.dart';
import 'package:app_101/models/order_models.dart';

void main() {
  test('encodes a versioned offline link and round-trips an OrderSession', () {
    final session = OrderSession(
      id: 'share_me',
      createdAt: DateTime(2026, 1, 2, 3, 4),
      people: const [Person(id: 'p1', name: 'Mona', emoji: '🙂', colorValue: 1)],
      lines: const [
        OrderLine(id: 'l1', personId: 'p1', title: 'Pizza', qty: 2, price: 50),
      ],
      groupName: 'Friday dinner',
    );

    final encoded = OrderQrPayload.encode(session);
    final decoded = OrderQrPayload.decode(encoded);

    expect(encoded, startsWith('crewbites://order?'));
    expect(encoded, contains('v=1'));
    expect(decoded, isNotNull);
    expect(decoded!.id, session.id);
    expect(decoded.people.single.name, 'Mona');
    expect(decoded.lines.single.lineTotal, 100);
    expect(decoded.groupName, 'Friday dinner');
  });

  test('rejects malformed, foreign, and unsupported links', () {
    expect(OrderQrPayload.decode('https://example.com/order?v=1&p=x'), isNull);
    expect(OrderQrPayload.decode('crewbites://order?v=2&p=x'), isNull);
    expect(OrderQrPayload.decode('crewbites://order?v=1&p=not-json'), isNull);
  });
}
