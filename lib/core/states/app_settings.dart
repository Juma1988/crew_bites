import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../extras_split_mode.dart';
import '../friend_icon_style.dart';
import '../values/app_values.dart';
import 'crew_store.dart';

/// App-wide settings: theme + language + prices + currency + coaches.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _keyTheme = AppValues.prefsTheme;
  static const _keyPalette = AppValues.prefsColorPalette;
  static const _keyLocale = AppValues.prefsLocale;
  static const _keyPrices = AppValues.prefsPrices;
  static const _keyCurrency = AppValues.prefsCurrency;
  static const _keyFriendIcons = AppValues.prefsFriendIconStyle;
  static const _keyExtrasSplit = AppValues.prefsExtrasSplit;
  static const _keyRoundTotals = AppValues.prefsRoundTotals;

  ThemeMode themeMode = ThemeMode.system;

  /// Active color seed (icons/assets unchanged).
  ColorPalette colorPalette = ColorPalette.coral;

  /// Default language: English.
  String _localeCode = 'en';
  bool _pricesEnabled = true;
  String currencyCode = AppValues.defaultCurrency;

  /// How friends are marked on food rows, Home, history and share.
  FriendIconStyle friendIconStyle = FriendIconStyle.firstTwo;

  /// How tip + delivery are shared among people.
  ExtrasSplitMode extrasSplitMode = ExtrasSplitMode.even;

  /// Round each person's share to whole units so the split sums exactly.
  bool roundTotals = false;

  /// Set when a prefs decode failed (UI can toast once).
  bool prefsLoadWarning = false;

  bool _ready = false;
  bool get ready => _ready;

  String get localeCode => _localeCode;

  bool get isArabic => localeCode == 'ar';
  Locale get locale => Locale(localeCode);
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  bool get pricesEnabled => _pricesEnabled;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyTheme);
      themeMode = switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      colorPalette = ColorPalette.fromId(prefs.getString(_keyPalette));
      final loc = prefs.getString(_keyLocale) ??
          prefs.getString(AppValues.prefsLocaleLegacy) ??
          'en';
      _localeCode = (loc == 'en') ? 'en' : 'ar';
      _pricesEnabled = prefs.getBool(_keyPrices) ?? true;
      final cur = prefs.getString(_keyCurrency) ?? AppValues.defaultCurrency;
      currencyCode = AppValues.currencyCodes.contains(cur)
          ? cur
          : AppValues.defaultCurrency;
      friendIconStyle =
          FriendIconStyle.fromKey(prefs.getString(_keyFriendIcons));
      extrasSplitMode =
          ExtrasSplitMode.fromKey(prefs.getString(_keyExtrasSplit));
      roundTotals = prefs.getBool(_keyRoundTotals) ?? false;
    } catch (_) {
      prefsLoadWarning = true;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      notePrefsCorrupt();
    }
  }

  void clearPrefsWarning() {
    if (!prefsLoadWarning) return;
    prefsLoadWarning = false;
    notifyListeners();
  }

  void notePrefsCorrupt() {
    prefsLoadWarning = true;
    notifyListeners();
  }

  Future<void> setPricesEnabled(bool value) async {
    if (_pricesEnabled == value) return;
    _pricesEnabled = value;
    notifyListeners();
    await _saveBool(_keyPrices, value);
  }

  Future<void> togglePrices() async {
    await setPricesEnabled(!_pricesEnabled);
  }

  Future<void> _save(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      notePrefsCorrupt();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _save(_keyTheme, value);
  }

  Future<void> setColorPalette(ColorPalette palette) async {
    if (palette == colorPalette) return;
    colorPalette = palette;
    notifyListeners();
    await _save(_keyPalette, palette.id);
  }

  Future<void> setLocaleCode(String code) async {
    final next = code == 'ar' ? 'ar' : 'en';
    if (next == _localeCode) return;
    _localeCode = next;
    notifyListeners();
    await _save(_keyLocale, next);
    await _save(AppValues.prefsLocaleLegacy, next);
  }

  Future<void> setCurrencyCode(String code) async {
    final next = AppValues.currencyCodes.contains(code)
        ? code
        : AppValues.defaultCurrency;
    if (next == currencyCode) return;
    currencyCode = next;
    notifyListeners();
    await _save(_keyCurrency, next);
  }

  Future<void> setFriendIconStyle(FriendIconStyle style) async {
    if (style == friendIconStyle) return;
    friendIconStyle = style;
    notifyListeners();
    await _save(_keyFriendIcons, style.key);
  }

  Future<void> setExtrasSplitMode(ExtrasSplitMode mode) async {
    if (mode == extrasSplitMode) return;
    extrasSplitMode = mode;
    notifyListeners();
    await _save(_keyExtrasSplit, mode.key);
  }

  Future<void> setRoundTotals(bool value) async {
    if (value == roundTotals) return;
    roundTotals = value;
    notifyListeners();
    await _saveBool(_keyRoundTotals, value);
  }

  /// Clears user-added names (prefs + [CrewStore] memory/UI).
  Future<void> clearCustomRoster() async {
    await CrewStore.instance.clearCustomPeople();
  }
}
