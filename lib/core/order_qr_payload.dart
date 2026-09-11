import 'dart:convert';

import '../models/order_models.dart';

/// Versioned, self-contained order link used by the offline QR/share flow.
///
/// The session is encoded directly into the URI; nothing is uploaded or
/// resolved remotely. Future readers can reject versions they do not know.
class OrderQrPayload {
  const OrderQrPayload._();

  static const scheme = 'crewbites';
  static const host = 'order';
  static const version = 1;
  static const _type = 'crew_bites_order';

  static String encode(OrderSession session) {
    final json = jsonEncode({
      'type': _type,
      'v': version,
      'session': session.toJson(),
    });
    final payload = base64Url.encode(utf8.encode(json));
    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: {'v': '$version', 'p': payload},
    ).toString();
  }

  static OrderSession? decode(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (uri.scheme != scheme || uri.host != host) return null;
      if (uri.queryParameters['v'] != '$version') return null;
      final payload = uri.queryParameters['p'];
      if (payload == null || payload.isEmpty) return null;
      final json = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (json is! Map || json['type'] != _type || json['v'] != version) {
        return null;
      }
      final session = json['session'];
      if (session is! Map) return null;
      return OrderSession.fromJson(Map<String, dynamic>.from(session));
    } catch (_) {
      return null;
    }
  }
}
