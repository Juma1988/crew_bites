/// UI constants for spacing, sizing, and animation durations.
/// Use these instead of hardcoded numbers in widgets.
abstract final class UIConstants {
  // ── Spacing ─────────────────────────────────────────────────────────
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 6.0;
  static const double spacingM = 8.0;
  static const double spacingL = 12.0;
  static const double spacingXL = 14.0;
  static const double spacingXXL = 16.0;
  static const double spacingXXXL = 20.0;
  static const double spacingMax = 24.0;

  // ── Padding ─────────────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 14.0;
  static const double paddingXL = 16.0;
  static const double paddingXXL = 18.0;
  static const double paddingXXXL = 20.0;
  static const double paddingMax = 22.0;
  static const double paddingPageHorizontal = 22.0;
  static const double paddingPageTop = 18.0;

  // ── Border Radius ───────────────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 14.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 18.0;
  static const double radiusCard = 24.0;
  static const double radiusPill = 999.0;

  // ── Icon Sizes ──────────────────────────────────────────────────────
  static const double iconSizeXS = 18.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 22.0;
  static const double iconSizeL = 26.0;
  static const double iconSizeXL = 28.0;

  // ── Font Sizes ──────────────────────────────────────────────────────
  static const double fontSizeXS = 9.0;
  static const double fontSizeS = 10.0;
  static const double fontSizeM = 12.0;
  static const double fontSizeL = 14.0;
  static const double fontSizeXL = 15.0;
  static const double fontSizeXXL = 16.0;

  // ── Avatar Sizes ────────────────────────────────────────────────────
  static const double avatarRadiusXS = 12.0;
  static const double avatarRadiusS = 16.0;
  static const double avatarRadiusM = 20.0;
  static const double avatarRadiusL = 24.0;

  // ── Animation Durations ─────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 120);
  static const Duration animNormal = Duration(milliseconds: 160);
  static const Duration animMedium = Duration(milliseconds: 180);
  static const Duration animSlow = Duration(milliseconds: 200);
  static const Duration animListDismiss = Duration(milliseconds: 280);
  static const Duration animIconPop = Duration(milliseconds: 220);
  static const Duration animPageTransition = Duration(milliseconds: 780);
  static const Duration animPageTransitionShort = Duration(milliseconds: 800);

  // ── Component Sizes ─────────────────────────────────────────────────
  static const double personRailWidth = 72.0;
  static const double minTouch = 48.0;
  static const double minTouchCompact = 44.0;
  static const double borderWidth = 1.5;
  static const double borderWidthSelected = 2.0;
  static const double borderWidthThick = 2.5;

  // ── Text Heights ────────────────────────────────────────────────────
  static const double textHeightTight = 1.15;
  static const double textHeightNormal = 1.3;
  static const double textHeightRelaxed = 1.5;
}
