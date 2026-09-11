import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/default.dart';
import '../../models/order_models.dart';
import '../services/shared_preferences_service.dart';
import '../values/app_values.dart';
import 'order_store.dart';

/// Crew roster + favorites + selection (ChangeNotifier — no setState here).
/// UI listens and rebuilds; call [notifyListeners] via public methods.
class CrewStore extends ChangeNotifier {
  CrewStore._();
  static final CrewStore instance = CrewStore._();

  List<String> names = [];
  final Set<String> selected = {};
  final Map<String, int> colors = {};
  final Map<String, String> emojis = {};
  final Set<String> favorites = {};
  bool ready = false;

  bool isDefault(String name) =>
      defaultNames.any((d) => d.toLowerCase() == name.toLowerCase());

  bool isFavorite(String name) =>
      favorites.any((f) => f.toLowerCase() == name.toLowerCase());

  int colorFor(String name, [int index = 0]) {
    if (colors.containsKey(name)) return colors[name]!;
    for (final e in colors.entries) {
      if (e.key.toLowerCase() == name.toLowerCase()) return e.value;
    }
    return PersonPalette.colorAt(index);
  }

  String emojiFor(String name) {
    if (emojis.containsKey(name)) return emojis[name]!;
    for (final e in emojis.entries) {
      if (e.key.toLowerCase() == name.toLowerCase()) return e.value;
    }
    return PersonPalette.randomEmoji(name.hashCode);
  }

  bool hasEmoji(String name) {
    if (emojis.containsKey(name)) return true;
    return emojis.keys.any((k) => k.toLowerCase() == name.toLowerCase());
  }

  void sortNames() {
    names.sort((a, b) {
      final af = isFavorite(a);
      final bf = isFavorite(b);
      if (af != bf) return af ? -1 : 1;
      return 0;
    });
  }

  Future<void> load() async {
    final prefs = await SharedPreferencesService.instance.get();
    await _loadCustom(prefs);
    await _loadFavorites(prefs);

    // First install / empty roster: seed Alex/Sam/Jordan once into prefs.
    // After that the roster is only what the user keeps (delete sticks).
    if (colors.isEmpty) {
      _seedStarterNames();
      await persistCustom(prefs);
    }

    names = colors.keys.toList();

    final current = await OrderStore.loadCurrent(prefs);
    final isNewOrder = current == null || current.people.isEmpty;

    if (isNewOrder) {
      // Pre-select favorites first, then any remaining names (capped).
      selected.clear();
      for (final n in names) {
        if (selected.length >= AppValues.maxCrewSelected) break;
        if (isFavorite(n)) selected.add(n);
      }
      for (final n in names) {
        if (selected.length >= AppValues.maxCrewSelected) break;
        if (!selected.contains(n)) selected.add(n);
      }
      await persistCustom(prefs);
    } else {
      for (final p in current.people) {
        if (!names.any((n) => n.toLowerCase() == p.name.toLowerCase())) {
          names.add(p.name);
          colors[p.name] = p.colorValue;
          if (p.emoji.isNotEmpty) emojis[p.name] = p.emoji;
        } else {
          colors[p.name] = p.colorValue;
          if (p.emoji.isNotEmpty) emojis[p.name] = p.emoji;
        }
        selected.add(
          names.firstWhere(
            (n) => n.toLowerCase() == p.name.toLowerCase(),
            orElse: () => p.name,
          ),
        );
      }
      await persistCustom(prefs);
    }

    for (final n in names) {
      if (!colors.containsKey(n) &&
          !colors.keys.any((k) => k.toLowerCase() == n.toLowerCase())) {
        colors[n] = PersonPalette.randomColor(n.hashCode);
      }
      if (!hasEmoji(n)) {
        emojis[n] = PersonPalette.randomEmoji(n.hashCode ^ 0x9e);
      }
    }
    await persistCustom(prefs);
    sortNames();
    ready = true;
    notifyListeners();
  }

  void _seedStarterNames() {
    for (final n in defaultNames) {
      colors[n] = PersonPalette.randomColor(n.hashCode);
      emojis[n] = PersonPalette.randomEmoji(n.hashCode ^ 0x9e);
    }
  }

  Future<void> _loadCustom(SharedPreferences prefs) async {
    final raw = prefs.getString(AppValues.prefsCustomRoster);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final name = m['name'] as String;
        colors[name] =
            m['color'] as int? ?? PersonPalette.randomColor(name.hashCode);
        final em = m['emoji'] as String?;
        if (em != null && em.isNotEmpty) emojis[name] = em;
      }
    } catch (_) {}
  }

  Future<void> _loadFavorites(SharedPreferences prefs) async {
    final raw = prefs.getString(AppValues.prefsFavorites);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      favorites
        ..clear()
        ..addAll(list.map((e) => e as String));
    } catch (_) {}
  }

  Future<void> persistCustom([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferencesService.instance.get();
    final all = <String>{...colors.keys, ...emojis.keys};
    final list = all
        .map(
          (name) => {
            'name': name,
            'color': colorFor(name),
            'emoji': emojiFor(name),
          },
        )
        .toList();
    await p.setString(AppValues.prefsCustomRoster, jsonEncode(list));
  }

  Future<void> persistFavorites([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferencesService.instance.get();
    await p.setString(
      AppValues.prefsFavorites,
      jsonEncode(favorites.toList()),
    );
  }

  /// Whether the roster can accept another name.
  bool get canAddToRoster =>
      names.length < AppValues.maxCrewRoster;

  /// Whether another person can be selected for this order.
  bool get canSelectMore =>
      selected.length < AppValues.maxCrewSelected;

  /// `true` if added; `false` if at roster cap.
  Future<bool> addPerson({
    required String name,
    required int colorValue,
    required String emoji,
  }) async {
    if (!canAddToRoster) return false;
    names.add(name);
    colors[name] = colorValue;
    emojis[name] = emoji;
    if (canSelectMore) selected.add(name);
    sortNames();
    await persistCustom();
    notifyListeners();
    return true;
  }

  /// `true` if selection changed; `false` if hit select cap while selecting.
  bool toggleSelect(String name) {
    if (selected.contains(name)) {
      selected.remove(name);
      notifyListeners();
      return true;
    }
    if (!canSelectMore) return false;
    selected.add(name);
    notifyListeners();
    return true;
  }

  Future<void> renamePerson({
    required String oldName,
    required String newName,
    required int colorValue,
    required String emoji,
  }) async {
    final i = names.indexOf(oldName);
    if (i >= 0) names[i] = newName;
    colors.remove(oldName);
    emojis.remove(oldName);
    colors[newName] = colorValue;
    emojis[newName] = emoji;
    if (selected.remove(oldName)) selected.add(newName);
    if (favorites.remove(oldName) ||
        favorites.any((f) => f.toLowerCase() == oldName.toLowerCase())) {
      favorites.removeWhere((f) => f.toLowerCase() == oldName.toLowerCase());
      favorites.add(newName);
    }
    sortNames();
    await persistCustom();
    await persistFavorites();
    notifyListeners();
  }

  /// Any name can be removed (including starter seeds). Stays gone until Undo / re-add.
  Future<bool> deletePerson(String name) async {
    final exists = names.any((n) => n.toLowerCase() == name.toLowerCase()) ||
        colors.keys.any((k) => k.toLowerCase() == name.toLowerCase());
    if (!exists) return false;
    names.removeWhere((n) => n.toLowerCase() == name.toLowerCase());
    colors.removeWhere((k, _) => k.toLowerCase() == name.toLowerCase());
    emojis.removeWhere((k, _) => k.toLowerCase() == name.toLowerCase());
    selected.removeWhere((n) => n.toLowerCase() == name.toLowerCase());
    favorites.removeWhere((f) => f.toLowerCase() == name.toLowerCase());
    await persistCustom();
    await persistFavorites();
    notifyListeners();
    return true;
  }

  /// Remove all non-favorite names from the roster. Called when an order finishes.
  Future<void> pruneNonFavorites() async {
    final toRemove = names
        .where((n) => !isFavorite(n))
        .toList();
    for (final name in toRemove) {
      names.remove(name);
      colors.remove(name);
      emojis.remove(name);
      selected.remove(name);
    }
    await persistCustom();
    notifyListeners();
  }

  /// Restore after Undo (selection / favorite optional).
  Future<bool> restorePerson({
    required String name,
    required int colorValue,
    required String emoji,
    bool wasSelected = false,
    bool wasFavorite = false,
  }) async {
    if (names.any((n) => n.toLowerCase() == name.toLowerCase())) {
      return true;
    }
    if (!canAddToRoster) return false;
    names.add(name);
    colors[name] = colorValue;
    emojis[name] = emoji;
    if (wasSelected && canSelectMore) selected.add(name);
    if (wasFavorite) favorites.add(name);
    sortNames();
    await persistCustom();
    await persistFavorites();
    notifyListeners();
    return true;
  }

  Future<void> toggleFavorite(String name) async {
    final was = isFavorite(name);
    if (was) {
      favorites.removeWhere((f) => f.toLowerCase() == name.toLowerCase());
    } else {
      favorites.add(name);
    }
    sortNames();
    await persistFavorites();
    notifyListeners();
  }

  /// Reset roster to starter names (Alex/Sam/Jordan). Settings clear.
  Future<void> clearCustomPeople() async {
    final prefs = await SharedPreferencesService.instance.get();
    await prefs.remove(AppValues.prefsCustomRoster);
    colors.clear();
    emojis.clear();
    _seedStarterNames();
    names = colors.keys.toList();
    selected
      ..clear()
      ..addAll(names.take(AppValues.maxCrewSelected));
    favorites.clear();
    sortNames();
    await persistCustom(prefs);
    await persistFavorites(prefs);
    notifyListeners();
  }

  /// Build [Person] list for selected crew (for order session).
  List<Person> buildSelectedPeople(OrderSession? existing) {
    final priorByName = {
      for (final p in existing?.people ?? const <Person>[]) p.name: p,
    };
    final people = <Person>[];
    for (var index = 0; index < names.length; index++) {
      final name = names[index];
      if (!selected.contains(name)) continue;
      final prior = priorByName[name];
      final color = colorFor(name, index);
      final emoji = emojiFor(name);
      people.add(
        prior?.copyWith(colorValue: color, emoji: emoji) ??
            Person(
              id: 'p_${DateTime.now().microsecondsSinceEpoch}_$index',
              name: name,
              emoji: emoji,
              colorValue: color,
            ),
      );
    }
    return people;
  }
}
