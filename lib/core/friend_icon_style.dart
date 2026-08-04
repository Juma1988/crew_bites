import '../models/order_models.dart';

/// How a friend's mark is drawn on food rows, Home, history and share.
enum FriendIconStyle {
  emoji('emoji'),
  roman('roman'),
  firstLetter('first_letter'),
  firstTwo('first_two');

  const FriendIconStyle(this.key);

  final String key;

  static FriendIconStyle fromKey(String? key) {
    for (final s in FriendIconStyle.values) {
      if (s.key == key) return s;
    }
    return FriendIconStyle.firstTwo;
  }
}

/// The mark text for [person] under [style]. [index] is the 0-based
/// position of the friend in the crew roster (used by the roman style).
String friendIconMark(Person person, FriendIconStyle style, int index) {
  return switch (style) {
    FriendIconStyle.emoji =>
      person.emoji.isNotEmpty ? person.emoji : person.initials,
    FriendIconStyle.roman => romanNumeral(index + 1),
    FriendIconStyle.firstLetter => firstLetterOf(person.name),
    FriendIconStyle.firstTwo => person.initials,
  };
}

/// True when the mark should render with emoji sizing / colors
/// (emoji style + the friend has an emoji).
bool friendUsesEmoji(Person person, FriendIconStyle style) =>
    style == FriendIconStyle.emoji && person.emoji.isNotEmpty;

/// Roman numeral for a 1-based number (I, II, III, …).
String romanNumeral(int n) {
  if (n < 1) n = 1;
  const table = <(int, String)>[
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];
  final buf = StringBuffer();
  for (final (value, symbol) in table) {
    while (n >= value) {
      buf.write(symbol);
      n -= value;
    }
  }
  return buf.toString();
}

/// First Latin / Arabic letter of [name], uppercased.
String firstLetterOf(String name) {
  for (final rune in name.runes) {
    final ch = String.fromCharCode(rune);
    if (RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(ch)) {
      return ch.toUpperCase();
    }
  }
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}
