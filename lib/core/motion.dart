import 'package:flutter/material.dart';

/// Shared motion helpers (respects reduced motion).
abstract final class AppMotion {
  static bool reduce(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration of(BuildContext context, Duration preferred) =>
      reduce(context) ? Duration.zero : preferred;
}
