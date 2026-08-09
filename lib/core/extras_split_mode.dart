/// How tip + delivery are shared among people on an order.
enum ExtrasSplitMode {
  /// Equal share for every person on the order.
  even('even'),

  /// Proportional to each person's food total (0 for people with no order).
  byValue('by_value');

  const ExtrasSplitMode(this.key);

  final String key;

  static ExtrasSplitMode fromKey(String? key) {
    for (final s in ExtrasSplitMode.values) {
      if (s.key == key) return s;
    }
    return ExtrasSplitMode.even;
  }
}
