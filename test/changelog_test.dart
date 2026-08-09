import 'package:flutter_test/flutter_test.dart';

import 'package:app_101/core/changelog.dart';
import 'package:app_101/core/values/app_values.dart';

List<int> _parse(String v) => v.split('.').map(int.parse).toList();

bool _newerOrEqual(List<int> a, List<int> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return a.length >= b.length;
}

void main() {
  test('changelog has an entry for the current app version', () {
    expect(Changelog.entryFor(AppValues.appVersion), isNotNull);
  });

  test('every entry has non-empty localized notes', () {
    expect(Changelog.entries, isNotEmpty);
    for (final e in Changelog.entries) {
      expect(e.notesEn, isNotEmpty, reason: '${e.version} EN notes');
      expect(e.notesAr, isNotEmpty, reason: '${e.version} AR notes');
      expect(e.notes(true).length, e.notesAr.length);
      expect(e.notes(false).length, e.notesEn.length);
    }
  });

  test('entries are ordered newest first', () {
    for (var i = 0; i < Changelog.entries.length - 1; i++) {
      final a = _parse(Changelog.entries[i].version);
      final b = _parse(Changelog.entries[i + 1].version);
      expect(
        _newerOrEqual(a, b),
        isTrue,
        reason: '${Changelog.entries[i].version} should be newer than '
            '${Changelog.entries[i + 1].version}',
      );
    }
  });
}
