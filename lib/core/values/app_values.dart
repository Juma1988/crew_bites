import 'package:flutter/material.dart';

/// Named app color palette (seed only — launcher/icons stay fixed).
/// Seeds tuned for food/crew vibe (inspired by FlexColorScheme-style palettes).
enum ColorPalette {
  /// Brand coral — matches launcher accent.
  coral('coral', Color(0xFFFF6B4A), Color(0xFFFFB347)),
  /// Blumine / tropical ocean.
  ocean('ocean', Color(0xFF1A6B8A), Color(0xFF5BC0BE)),
  /// Eggplant / berry.
  grape('grape', Color(0xFF7B2CBF), Color(0xFFC77DFF)),
  /// Wasabi / fresh greens.
  mint('mint', Color(0xFF2D6A4F), Color(0xFF95D5B2)),
  /// Mango mojito — warm orange + gold (id kept for prefs).
  sunset('sunset', Color(0xFFF4A261), Color(0xFFE9C46A)),
  /// Neon — unlocked via easter egg (swipe down 5× on summary).
  neon('neon', Color(0xFF39FF14), Color(0xFFFF1493));

  const ColorPalette(this.id, this.seed, this.accent);

  final String id;
  final Color seed;
  final Color accent;

  static ColorPalette fromId(String? raw) {
    for (final p in ColorPalette.values) {
      if (p.id == raw) return p;
    }
    return ColorPalette.coral;
  }
}

/// Single home for app-wide **values** (numbers, colors, keys, limits).
/// UI strings stay in [Translate]; ThemeData stays in [AppTheme].
///
/// Prefer reading from here instead of magic numbers in widgets.
abstract final class AppValues {
  // ── Brand ───────────────────────────────────────────────────────────

  static const String brandName = 'Crew Bites';
  static const String appVersion = '1.0.0';

  // ── Layout / shape ──────────────────────────────────────────────────

  static const double radiusCard = 24;
  static const double radiusButton = 18;
  static const double radiusInput = 16;
  static const double radiusChip = 14;
  static const double radiusPill = 999;
  static const double minTouch = 48;
  static const double minTouchCompact = 44;

  static const double pagePaddingH = 22;
  static const double pagePaddingTop = 18;
  static const double crewRailWidth = 72;
  static const double personAvatarRadius = 24;

  // ── Animation ───────────────────────────────────────────────────────

  static const Duration animFast = Duration(milliseconds: 160);
  static const Duration animNormal = Duration(milliseconds: 200);
  /// Food row swipe dismiss + list collapse.
  static const Duration animListDismiss = Duration(milliseconds: 280);
  /// Assignee chip enter/leave on undo / assign.
  static const Duration animIconPop = Duration(milliseconds: 220);
  static const Duration snackShort = Duration(seconds: 2);
  static const Duration snackTiny = Duration(seconds: 1);

  // ── Limits ──────────────────────────────────────────────────────────

  static const int maxHistory = 3;
  static const int maxNameLength = 24;

  /// Max friends saved in the roster (prevents unbounded prefs growth).
  static const int maxCrewRoster = 24;

  /// Max people selected on one order (UI / share stays readable).
  static const int maxCrewSelected = 12;

  // ── Theme seed (used by AppTheme) ───────────────────────────────────

  /// Default brand coral (same as [ColorPalette.coral] seed).
  static const Color seedColor = Color(0xFFFF6B4A);
  static const Color accentColor = Color(0xFFFFB347);

  /// Named color palettes — seed only; icons/assets unchanged.
  static const List<ColorPalette> colorPalettes = ColorPalette.values;

  static const String defaultPaletteId = 'coral';

  // ── Prices toggle (text) ────────────────────────────────────────────

  static const Color pricesOn = Color(0xFF0CA678);
  static const Color pricesOnDark = Color(0xFF69DB7C);
  static const Color pricesOff = Color(0xFF868E96);
  static const double pricesFontSize = 15;

  // ── SharedPreferences keys ──────────────────────────────────────────

  static const String prefsTheme = 'theme_mode';
  static const String prefsColorPalette = 'color_palette';
  static const String prefsLocale = 'app_locale';
  static const String prefsPrices = 'prices_enabled';
  static const String prefsCustomRoster = 'custom_roster';
  static const String prefsRestaurantGroups = 'restaurant_groups';
  static const String prefsFavorites = 'favorites';
  static const String prefsLocaleLegacy = 'locale';
  static const String prefsCurrent = 'current';
  static const String prefsHistory = 'history';
  static const String prefsCurrency = 'currency_code';
  static const String prefsFriendIconStyle = 'friend_icon_style';

  // ── Easter eggs ─────────────────────────────────────────────────────
  static const String prefsNeonUnlocked = 'easter_egg_neon_unlocked';

  // ── Currency ────────────────────────────────────────────────────────

  /// Supported currency codes (display suffixes live in Translate).
  static const List<String> currencyCodes = ['EGP', 'USD', 'SAR', 'EUR'];
  static const String defaultCurrency = 'EGP';

  // ── Routes ──────────────────────────────────────────────────────────

  static const String routeHome = '/';
  static const String routeAddUser = '/add-user';
  static const String routeAddOrders = '/add-orders';
  static const String routeOutputHistory = '/output-history';
  static const String routeHistory = '/history';
  static const String routeSettings = '/settings';
  static const String routePrivacy = '/privacy';

  // ── Bundle ids ──────────────────────────────────────────────────────

  static const String bundleFreeform = 'freeform';
  static const String bundleWemby = 'wemby';
  static const String bundleAboFars = 'abo_fars';

  // ── Special food item keys (order-level, not per-person) ────────────

  static const String extrasItemKey = 'extras';

  /// Keys that represent order-level extras (tip, delivery).
  static const Set<String> specialFoodKeys = {extrasItemKey};

  // ── Person palette (funny faces + colors) ───────────────────────────

  static const List<int> personColors = [
    0xFFFF6B6B,
    0xFFFF8E53,
    0xFFFFD93D,
    0xFF6BCB77,
    0xFF4D96FF,
    0xFF9B5DE5,
    0xFFF15BB5,
    0xFF00BBF9,
    0xFFFF9FF3,
    0xFF54A0FF,
    0xFF5F27CD,
    0xFF01A3A4,
  ];

  static const List<String> personEmojis = [
    '😂',
    '🤣',
    '😜',
    '🤪',
    '🥳',
    '😎',
    '🤓',
    '🤠',
    '😺',
    '😹',
    '🦊',
    '🐼',
    '🐨',
    '🦄',
    '🐸',
    '🐵',
    '🐧',
    '🍕',
    '🌮',
    '🍩',
    '🍦',
    '🥑',
    '🔥',
    '⭐',
    '🌈',
    '🤖',
    '👻',
    '🚀',
  ];
}
