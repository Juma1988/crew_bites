import 'order_models.dart';

/// Route arguments for [OutputHistoryPage].
class OutputHistoryArgs {
  const OutputHistoryArgs({
    this.session,
    this.fromHistory = false,
  });

  /// When non-null, show this session instead of loading current prefs.
  final OrderSession? session;

  /// True when opened from a Home history peek (read-only + order again).
  final bool fromHistory;
}
