import 'package:flutter/services.dart';

/// Light device feedback used by taps and primary actions.
abstract final class AppHaptics {
  static Future<void> selectionClick() => HapticFeedback.selectionClick();

  static Future<void> lightImpact() => HapticFeedback.lightImpact();

  static Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  static Future<void> heavyImpact() => HapticFeedback.heavyImpact();
}
