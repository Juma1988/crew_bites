import 'dart:convert';

import '../core/values/app_values.dart';

/// A short “hits” food list for a restaurant bundle (not a full menu).
class RestaurantGroup {
  const RestaurantGroup({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.emoji = '🍽️',
    required this.colorValue,
    required this.items,
    this.itemPrices = const {},
    this.isBuiltIn = false,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String emoji;
  final int colorValue;

  /// Menu placeholders / user-edited items for this bundle.
  final List<String> items;

  /// Unit price per food title (lowercase keys). Persists with the bundle.
  final Map<String, double> itemPrices;

  final bool isBuiltIn;

  /// English name (history / share snapshot).
  String get name => nameEn;

  /// English name with each word capitalized (for display).
  String get titleCaseName => titleCaseNameOf(nameEn);

  /// Capitalize the first Latin letter of each word in [name].
  /// Non-Latin scripts (e.g. Arabic) are left unchanged.
  static String titleCaseNameOf(String name) {
    final buf = <String>[];
    for (final w in name.trim().split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      final runes = w.runes.toList();
      final ch = String.fromCharCode(runes.first);
      if (RegExp(r'[A-Za-z]').hasMatch(ch)) {
        buf.add(ch.toUpperCase() + w.substring(1));
      } else {
        buf.add(w);
      }
    }
    return buf.join(' ');
  }

  String displayName({required bool arabic}) => arabic ? nameAr : titleCaseName;

  double priceForItem(String title) {
    final key = title.toLowerCase();
    return itemPrices[key] ?? 0;
  }

  RestaurantGroup copyWith({
    String? id,
    String? nameEn,
    String? nameAr,
    String? emoji,
    int? colorValue,
    List<String>? items,
    Map<String, double>? itemPrices,
    bool? isBuiltIn,
  }) {
    return RestaurantGroup(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      items: items ?? this.items,
      itemPrices: itemPrices ?? this.itemPrices,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  /// Merge [prices] (title → unit price) onto this bundle’s [itemPrices].
  /// Only foods already listed on [items] are stored.
  RestaurantGroup withItemPrices(Map<String, double> prices) {
    if (prices.isEmpty) return this;
    final next = Map<String, double>.from(itemPrices);
    var changed = false;
    for (final e in prices.entries) {
      if (e.value <= 0) continue;
      final key = e.key.toLowerCase().trim();
      final hasItem = items.any((i) => i.toLowerCase().trim() == key);
      if (!hasItem) continue;
      if (next[key] != e.value) {
        next[key] = e.value;
        changed = true;
      }
    }
    return changed ? copyWith(itemPrices: next) : this;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': nameEn,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'emoji': emoji,
        'color': colorValue,
        'items': items,
        if (itemPrices.isNotEmpty) 'itemPrices': itemPrices,
        'isBuiltIn': isBuiltIn,
      };

  factory RestaurantGroup.fromJson(Map<String, dynamic> json) {
    final en = (json['nameEn'] as String?) ??
        (json['name'] as String?) ??
        'Bundle';
    final ar = (json['nameAr'] as String?) ?? en;
    final rawPrices = json['itemPrices'];
    final prices = <String, double>{};
    if (rawPrices is Map) {
      rawPrices.forEach((k, v) {
        prices[k.toString().toLowerCase()] = (v as num).toDouble();
      });
    }
    return RestaurantGroup(
      id: json['id'] as String,
      nameEn: en,
      nameAr: ar,
      emoji: json['emoji'] as String? ?? '🍽️',
      colorValue: json['color'] as int? ?? 0xFF4D96FF,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      itemPrices: prices,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  static String encodeList(List<RestaurantGroup> groups) =>
      jsonEncode(groups.map((g) => g.toJson()).toList());

  static List<RestaurantGroup> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RestaurantGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// No bundle selected — empty custom menu.
  static const freeformId = AppValues.bundleFreeform;

  /// Always-present order-level items in every bundle's food list.
  static const List<String> specialItems = [
    AppValues.extrasItemKey,
  ];

  static RestaurantGroup freeform() => const RestaurantGroup(
        id: freeformId,
        nameEn: 'Freeform',
        nameAr: 'حر',
        emoji: '📝',
        colorValue: 0xFF4D96FF,
        items: [],
        isBuiltIn: true,
      );

  static const wembyId = AppValues.bundleWemby;
  static const aboFarsId = AppValues.bundleAboFars;

  /// Map legacy group ids → current ids.
  static String migrateId(String? id) {
    return switch (id) {
      null || '' => freeformId,
      'wemes' || 'wemby' => wembyId,
      'al_zaheem' || 'abo_fars' => aboFarsId,
      _ => id,
    };
  }

  /// Built-in bundle seeds. New users start empty — only Freeform ships.
  /// Legacy ids (Wemby / Abo fars) are still migrated for old saved prefs.
  static List<RestaurantGroup> builtInSeeds() => [
        freeform(),
      ];

  /// Bundles shown as pills (excludes freeform).
  static List<RestaurantGroup> bundlePills() =>
      builtInSeeds().where((g) => g.id != freeformId).toList();
}
