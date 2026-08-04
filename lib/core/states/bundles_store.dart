import 'package:shared_preferences/shared_preferences.dart';

import '../../models/restaurant_group.dart';

import '../values/app_values.dart';

/// Restaurant bundle list load/save/edit (no UI).
abstract final class BundlesStore {
  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<List<RestaurantGroup>> load([
    SharedPreferences? prefs,
  ]) async {
    final p = prefs ?? await _prefs();
    final saved = RestaurantGroup.decodeList(
      p.getString(AppValues.prefsRestaurantGroups),
    );
    final byId = {
      for (final g in saved) RestaurantGroup.migrateId(g.id): g,
    };
    final out = <RestaurantGroup>[];
    for (final seed in RestaurantGroup.builtInSeeds()) {
      final savedGroup = byId.remove(seed.id);
      if (savedGroup == null) {
        out.add(seed);
      } else if (seed.id == RestaurantGroup.freeformId) {
        out.add(seed);
      } else {
        out.add(
          seed.copyWith(
            items: List<String>.from(savedGroup.items),
            itemPrices: Map<String, double>.from(savedGroup.itemPrices),
            emoji: savedGroup.emoji.isNotEmpty ? savedGroup.emoji : seed.emoji,
            colorValue: savedGroup.colorValue,
          ),
        );
      }
    }
    for (final g in byId.values) {
      if (g.id != RestaurantGroup.freeformId) {
        out.add(g.isBuiltIn ? g.copyWith(isBuiltIn: false) : g);
      }
    }
    return out;
  }

  static Future<void> save(
    List<RestaurantGroup> groups, [
    SharedPreferences? prefs,
  ]) async {
    final p = prefs ?? await _prefs();
    final encoded = RestaurantGroup.encodeList(groups);
    await p.setString(AppValues.prefsRestaurantGroups, encoded);
  }

  static List<RestaurantGroup> replace(
    List<RestaurantGroup> groups,
    RestaurantGroup next,
  ) {
    return [
      for (final g in groups) g.id == next.id ? next : g,
    ];
  }

  static List<RestaurantGroup> remove(
    List<RestaurantGroup> groups,
    String id,
  ) {
    return groups.where((g) => g.id != id).toList();
  }

  static List<RestaurantGroup> pillsOnly(List<RestaurantGroup> groups) {
    return groups
        .where((g) => g.id != RestaurantGroup.freeformId)
        .toList();
  }

  /// Write unit prices onto every bundle that lists those foods.
  /// [prices] keys are food titles (any case); values ≤ 0 are skipped.
  /// Optionally force-update [preferGroupId] even when other groups also match.
  static List<RestaurantGroup> applyItemPrices(
    List<RestaurantGroup> groups,
    Map<String, double> prices, {
    String? preferGroupId,
  }) {
    if (prices.isEmpty) return groups;
    final normalized = <String, double>{
      for (final e in prices.entries)
        if (e.value > 0) e.key.toLowerCase().trim(): e.value,
    };
    if (normalized.isEmpty) return groups;

    return [
      for (final g in groups) g.withItemPrices(normalized),
    ];
  }
}
