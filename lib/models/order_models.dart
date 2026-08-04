import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/values/app_values.dart';

/// One friend in the group — name + color + funny emoji avatar.
class Person {
  const Person({
    required this.id,
    required this.name,
    this.emoji = '',
    required this.colorValue,
  });

  final String id;
  final String name;
  /// Kept for prefs compatibility; UI uses [initials] instead.
  final String emoji;
  final int colorValue;

  Color get color => Color(colorValue);

  /// First 2 letters of the name (e.g. "Hany" → "HA", "Dr. Tark" → "DR").
  String get initials => initialsOf(name);

  /// Extract up to 2 letters from [name] (Latin / Arabic), uppercased.
  static String initialsOf(String name) {
    final buf = StringBuffer();
    for (final rune in name.runes) {
      final ch = String.fromCharCode(rune);
      if (RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(ch)) {
        buf.write(ch);
        if (buf.length >= 2) break;
      }
    }
    final s = buf.toString();
    if (s.isEmpty) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return '?';
      return trimmed
          .substring(0, trimmed.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return s.toUpperCase();
  }

  Person copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': colorValue,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '',
        colorValue: json['color'] as int? ?? 0xFF7C4DFF,
      );
}

/// One food line for a person.
class OrderLine {
  const OrderLine({
    required this.id,
    required this.personId,
    required this.title,
    this.qty = 1,
    this.note = '',
    this.price = 0,
  });

  final String id;
  final String personId;
  final String title;
  final int qty;
  final String note;

  /// Unit price (numbers only in UI). Total = [price] * [qty].
  final double price;

  double get lineTotal => price * qty;

  OrderLine copyWith({
    String? id,
    String? personId,
    String? title,
    int? qty,
    String? note,
    double? price,
  }) {
    return OrderLine(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      title: title ?? this.title,
      qty: qty ?? this.qty,
      note: note ?? this.note,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'title': title,
        'qty': qty,
        'note': note,
        'price': price,
      };

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        id: json['id'] as String,
        personId: json['personId'] as String,
        title: json['title'] as String,
        qty: json['qty'] as int? ?? 1,
        note: json['note'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}

/// Full session: people + items + place + dates. Used for current + history.
class OrderSession {
  const OrderSession({
    required this.id,
    required this.createdAt,
    required this.people,
    required this.lines,
    this.updatedAt,
    this.groupId,
    this.groupName,
    this.foodPrices = const {},
    this.tipAmount = 0,
    this.deliveryFee = 0,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Person> people;
  final List<OrderLine> lines;

  /// Active restaurant group id (`freeform` or null = freeform).
  final String? groupId;

  /// Snapshot display name (e.g. "Al Zaheem") for history / share.
  final String? groupName;

  /// Unit price per food title (lowercased key). Used for menu + new lines.
  final Map<String, double> foodPrices;

  /// Optional tip for whole order (offline one-phone mode).
  final double tipAmount;

  /// Optional delivery fee for whole order.
  final double deliveryFee;

  bool get isEmpty => people.isEmpty && lines.isEmpty;
  bool get hasContent => people.isNotEmpty || lines.isNotEmpty;
  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);

  /// Food subtotal only (no tip / delivery).
  double get orderTotal =>
      lines.fold(0.0, (sum, l) => sum + l.lineTotal);

  /// Food + tip + delivery.
  double get grandTotal => orderTotal + tipAmount + deliveryFee;

  bool get hasPlace =>
      groupId != null &&
      groupId!.isNotEmpty &&
      groupId != 'freeform' &&
      (groupName != null && groupName!.isNotEmpty);

  List<OrderLine> linesFor(String personId) =>
      lines.where((l) => l.personId == personId).toList();

  /// Food total for one person (no tip / delivery share).
  double personTotal(String personId) =>
      linesFor(personId).fold(0.0, (sum, l) => sum + l.lineTotal);

  /// People who ordered at least one item.
  List<Person> get peopleWithOrders =>
      people.where((p) => linesFor(p.id).isNotEmpty).toList();

  /// Share of tip+delivery for [personId].
  /// Split equally among all people on the order.
  double personExtrasShare(String personId) {
    final extras = tipAmount + deliveryFee;
    if (extras <= 0) return 0;
    if (people.isEmpty) return 0;
    if (!people.any((p) => p.id == personId)) return 0;
    return extras / people.length;
  }

  /// Food + tip/delivery share for one person.
  double personGrandTotal(String personId) =>
      personTotal(personId) + personExtrasShare(personId);

  /// Whole-order rollup: each food title → total units (and price if set).
  List<FoodAggregate> aggregateFoods() {
    final map = <String, FoodAggregate>{};
    for (final l in lines) {
      final key = l.title.toLowerCase();
      final prev = map[key];
      if (prev == null) {
        map[key] = FoodAggregate(
          title: l.title,
          qty: l.qty,
          unitPrice: l.price,
        );
      } else {
        map[key] = FoodAggregate(
          title: prev.title,
          qty: prev.qty + l.qty,
          unitPrice: prev.unitPrice > 0 ? prev.unitPrice : l.price,
        );
      }
    }
    return map.values.toList();
  }

  double priceForTitle(String title) {
    final key = title.toLowerCase();
    if (foodPrices.containsKey(key)) return foodPrices[key]!;
    for (final l in lines) {
      if (l.title.toLowerCase() == key && l.price > 0) return l.price;
    }
    return 0;
  }

  OrderSession copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Person>? people,
    List<OrderLine>? lines,
    String? groupId,
    String? groupName,
    Map<String, double>? foodPrices,
    double? tipAmount,
    double? deliveryFee,
    bool clearGroup = false,
  }) {
    return OrderSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      people: people ?? this.people,
      lines: lines ?? this.lines,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      groupName: clearGroup ? null : (groupName ?? this.groupName),
      foodPrices: foodPrices ?? this.foodPrices,
      tipAmount: tipAmount ?? this.tipAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  OrderSession snapshot() => OrderSession(
        id: id,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        people: List<Person>.from(people),
        lines: List<OrderLine>.from(lines),
        groupId: groupId,
        groupName: groupName,
        foodPrices: Map<String, double>.from(foodPrices),
        tipAmount: tipAmount,
        deliveryFee: deliveryFee,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
        'people': people.map((p) => p.toJson()).toList(),
        'lines': lines.map((l) => l.toJson()).toList(),
        if (groupId != null) 'groupId': groupId,
        if (groupName != null) 'groupName': groupName,
        if (foodPrices.isNotEmpty) 'foodPrices': foodPrices,
        if (tipAmount > 0) 'tipAmount': tipAmount,
        if (deliveryFee > 0) 'deliveryFee': deliveryFee,
      };

  String encode() => jsonEncode(toJson());

  factory OrderSession.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['foodPrices'];
    final prices = <String, double>{};
    if (rawPrices is Map) {
      rawPrices.forEach((k, v) {
        prices[k.toString().toLowerCase()] = (v as num).toDouble();
      });
    }
    return OrderSession(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      people: (json['people'] as List<dynamic>? ?? [])
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList(),
      lines: (json['lines'] as List<dynamic>? ?? [])
          .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      foodPrices: prices,
      tipAmount: (json['tipAmount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
    );
  }

  static OrderSession? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return OrderSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Decode or return null and set [corrupt] when JSON is broken.
  static OrderSession? decodeChecked(String? raw, {void Function()? onCorrupt}) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return OrderSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      onCorrupt?.call();
      return null;
    }
  }

  static OrderSession empty() {
    final now = DateTime.now();
    return OrderSession(
      id: 's_${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      people: const [],
      lines: const [],
    );
  }
}

/// One food across the whole order (summed units).
class FoodAggregate {
  const FoodAggregate({
    required this.title,
    required this.qty,
    this.unitPrice = 0,
  });

  final String title;
  final int qty;
  final double unitPrice;

  double get lineTotal => unitPrice * qty;
}

/// Fun palette for people chips — values from [AppValues].
abstract final class PersonPalette {
  static const List<int> colors = AppValues.personColors;
  static const List<String> emojis = AppValues.personEmojis;

  static int colorAt(int index) => colors[index % colors.length];
  static String emojiAt(int index) => emojis[index % emojis.length];

  static final _rng = Random();

  static int randomColor([int? seed]) {
    if (seed != null) return colors[seed.abs() % colors.length];
    return colors[_rng.nextInt(colors.length)];
  }

  static String randomEmoji([int? seed]) {
    if (seed != null) return emojis[seed.abs() % emojis.length];
    return emojis[_rng.nextInt(emojis.length)];
  }

  /// Pair that looks fun together (independent rolls).
  static ({int color, String emoji}) randomLook() => (
        color: randomColor(),
        emoji: randomEmoji(),
      );
}
