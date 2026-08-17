import 'package:flutter/foundation.dart';

/// Global registry that pages write to and the debug overlay reads from.
///
/// Pages call `DebugRegistry.currentFile.value = 'lib/screens/xxx.dart'` in
/// their `build` method. Because Flutter builds the current page last during
/// a navigation transition, this value always reflects the topmost visible
/// page. The [DebugOverlay] listens to it and shows the chip.
abstract final class DebugRegistry {
  /// Relative path to the dart file of the currently visible page, or `null`
  /// when no page has registered yet.
  static final ValueNotifier<String?> currentFile = ValueNotifier<String?>(null);
}
