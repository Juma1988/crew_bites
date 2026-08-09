import 'package:flutter/material.dart';

/// Shared navigator so settings rebuilds keep the route stack, and tests /
/// bootstrap can reach the navigator without holding a widget reference.
abstract final class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}
