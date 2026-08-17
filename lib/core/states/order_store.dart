import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/order_models.dart';
import '../values/app_values.dart';

/// Order session + history load/save (no UI / setState).
/// Screens call these, then update local state / notify.
abstract final class OrderStore {
  static const currentKey = AppValues.prefsCurrent;
  static const historyKey = AppValues.prefsHistory;
  static const maxHistory = AppValues.maxHistory;

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<OrderSession?> loadCurrent([
    SharedPreferences? prefs,
    void Function()? onCorrupt,
  ]) async {
    final p = prefs ?? await _prefs();
    return OrderSession.decodeChecked(
      p.getString(currentKey),
      onCorrupt: onCorrupt,
    );
  }

  static Future<void> saveCurrent(
    OrderSession? session, [
    SharedPreferences? prefs,
  ]) async {
    final p = prefs ?? await _prefs();
    if (session == null || session.isEmpty) {
      await p.remove(currentKey);
      return;
    }
    final stamped = session.copyWith(updatedAt: DateTime.now());
    final encoded = stamped.encode();
    await p.setString(currentKey, encoded);
  }

  static Future<List<OrderSession>> loadHistory([
    SharedPreferences? prefs,
    void Function()? onCorrupt,
  ]) async {
    final p = prefs ?? await _prefs();
    final raw = p.getString(historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = <OrderSession>[];
      var anyBad = false;
      for (final e in list) {
        try {
          out.add(OrderSession.fromJson(e as Map<String, dynamic>));
        } catch (_) {
          anyBad = true;
        }
      }
      if (anyBad) onCorrupt?.call();
      return out;
    } catch (_) {
      onCorrupt?.call();
      return [];
    }
  }

  /// Restore a past session as the active order (for “order again”).
  static Future<void> restoreAsCurrent(
    OrderSession session, [
    SharedPreferences? prefs,
  ]) async {
    final p = prefs ?? await _prefs();
    final now = DateTime.now();
    final restored = OrderSession(
      id: 's_${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      people: List<Person>.from(session.people),
      lines: List<OrderLine>.from(session.lines),
      groupId: session.groupId,
      groupName: session.groupName,
      foodPrices: Map<String, double>.from(session.foodPrices),
      tip: session.tip,
      delivery: session.delivery,
      tax: session.tax,
      service: session.service,
    );
    await saveCurrent(restored, p);
  }

  static Future<void> saveHistory(
    List<OrderSession> history, [
    SharedPreferences? prefs,
  ]) async {
    final p = prefs ?? await _prefs();
    final capped = history.take(maxHistory).toList();
    if (capped.isEmpty) {
      await p.remove(historyKey);
    } else {
      await p.setString(
        historyKey,
        jsonEncode(capped.map((e) => e.toJson()).toList()),
      );
    }
  }

  /// Put [session] at front of history (dedupe by id, cap max).
  static Future<List<OrderSession>> pushHistory(
    OrderSession session,
    List<OrderSession> existing, [
    SharedPreferences? prefs,
  ]) async {
    if (!session.hasContent) return existing;
    final next = [session.snapshot(), ...existing];
    final seen = <String>{};
    final unique = <OrderSession>[];
    for (final s in next) {
      if (seen.add(s.id)) unique.add(s);
    }
    final capped = unique.take(maxHistory).toList();
    await saveHistory(capped, prefs);
    return capped;
  }

  /// Archive current (if content) and clear — “new order”.
  static Future<void> startNewOrder([SharedPreferences? prefs]) async {
    final p = prefs ?? await _prefs();
    final current = await loadCurrent(p);
    if (current != null && current.hasContent) {
      final history = await loadHistory(p);
      await pushHistory(current, history, p);
    }
    await saveCurrent(null, p);
  }

  /// Food titles already on the order (unique, order preserved).
  static List<String> foodTitlesFromSession(OrderSession? session) {
    if (session == null || session.lines.isEmpty) return [];
    final seen = <String>{};
    final out = <String>[];
    for (final l in session.lines) {
      final key = l.title.toLowerCase();
      if (seen.add(key)) out.add(l.title);
    }
    return out;
  }

  /// Merge bundle items into a food menu (no duplicates).
  static List<String> mergeFoods(List<String> menu, List<String> toAdd) {
    final out = List<String>.from(menu);
    for (final item in toAdd) {
      if (!out.any((f) => f.toLowerCase() == item.toLowerCase())) {
        out.add(item);
      }
    }
    return out;
  }

  /// +1 qty for [personId] + [foodTitle], or add new line.
  static OrderSession addFoodUnit(
    OrderSession session,
    String personId,
    String foodTitle, {
    double? unitPrice,
  }) {
    final key = foodTitle.toLowerCase();
    final price = unitPrice ?? session.priceForTitle(foodTitle);
    final lines = List<OrderLine>.from(session.lines);
    final idx = lines.indexWhere(
      (l) => l.personId == personId && l.title.toLowerCase() == key,
    );
    if (idx >= 0) {
      final cur = lines[idx];
      lines[idx] = cur.copyWith(
        qty: cur.qty + 1,
        price: price > 0 ? price : cur.price,
      );
    } else {
      lines.add(
        OrderLine(
          id: 'l_${DateTime.now().microsecondsSinceEpoch}_$personId',
          personId: personId,
          title: foodTitle,
          qty: 1,
          price: price,
        ),
      );
    }
    return session.copyWith(lines: lines, updatedAt: DateTime.now());
  }

  /// Set unit price for a food title on all matching lines + [foodPrices] map.
  static OrderSession setFoodPrice(
    OrderSession session,
    String foodTitle,
    double price,
  ) {
    final key = foodTitle.toLowerCase();
    final safe = price < 0 ? 0.0 : price;
    final prices = Map<String, double>.from(session.foodPrices);
    prices[key] = safe;
    final lines = [
      for (final l in session.lines)
        if (l.title.toLowerCase() == key) l.copyWith(price: safe) else l,
    ];
    return session.copyWith(
      lines: lines,
      foodPrices: prices,
      updatedAt: DateTime.now(),
    );
  }

  /// Format number for display (no currency symbol — numbers only).
  static String formatPrice(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  /// −1 qty for [personId] + [foodTitle]; drop line at 0.
  static OrderSession? undoFoodUnit(
    OrderSession session,
    String personId,
    String foodTitle,
  ) {
    final key = foodTitle.toLowerCase();
    final lines = <OrderLine>[];
    var changed = false;
    for (final l in session.lines) {
      if (!changed && l.personId == personId && l.title.toLowerCase() == key) {
        changed = true;
        if (l.qty > 1) lines.add(l.copyWith(qty: l.qty - 1));
      } else {
        lines.add(l);
      }
    }
    if (!changed) {
      return null;
    }
    return session.copyWith(lines: lines, updatedAt: DateTime.now());
  }
}
