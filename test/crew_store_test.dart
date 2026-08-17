import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/states/crew_store.dart';
import 'package:app_101/models/order_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    // Reset the singleton state
    CrewStore.instance.names.clear();
    CrewStore.instance.selected.clear();
    CrewStore.instance.colors.clear();
    CrewStore.instance.emojis.clear();
    CrewStore.instance.favorites.clear();
    CrewStore.instance.ready = false;
  });

  group('CrewStore.renamePerson', () {
    test('updates all data structures atomically', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali', 'Sara']);
      store.colors['Ali'] = 0xFF000001;
      store.colors['Sara'] = 0xFF000002;
      store.emojis['Ali'] = '😎';
      store.emojis['Sara'] = '🙂';
      store.selected.add('Ali');
      store.favorites.add('Ali');

      await store.renamePerson(
        oldName: 'Ali',
        newName: 'Alex',
        colorValue: 0xFF000003,
        emoji: '🍕',
      );

      expect(store.names, contains('Alex'));
      expect(store.names, isNot(contains('Ali')));
      expect(store.colors['Alex'], 0xFF000003);
      expect(store.colors.containsKey('Ali'), isFalse);
      expect(store.emojis['Alex'], '🍕');
      expect(store.emojis.containsKey('Ali'), isFalse);
      expect(store.selected, contains('Alex'));
      expect(store.selected, isNot(contains('Ali')));
      expect(store.isFavorite('Alex'), isTrue);
      expect(store.isFavorite('Ali'), isFalse);
    });

    test('preserves other people data', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali', 'Sara', 'Omar']);
      store.colors['Ali'] = 0xFF000001;
      store.colors['Sara'] = 0xFF000002;
      store.colors['Omar'] = 0xFF000003;
      store.emojis['Ali'] = '😎';
      store.emojis['Sara'] = '🙂';
      store.emojis['Omar'] = '🍔';

      await store.renamePerson(
        oldName: 'Ali',
        newName: 'Alex',
        colorValue: 0xFF000010,
        emoji: '🍕',
      );

      expect(store.colors['Sara'], 0xFF000002);
      expect(store.colors['Omar'], 0xFF000003);
      expect(store.emojis['Sara'], '🙂');
      expect(store.emojis['Omar'], '🍔');
    });
  });

  group('CrewStore.deletePerson', () {
    test('removes person from all data structures', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali', 'Sara']);
      store.colors['Ali'] = 0xFF000001;
      store.colors['Sara'] = 0xFF000002;
      store.emojis['Ali'] = '😎';
      store.emojis['Sara'] = '🙂';
      store.selected.add('Ali');
      store.favorites.add('Ali');

      final result = await store.deletePerson('Ali');
      expect(result, isTrue);
      expect(store.names, isNot(contains('Ali')));
      expect(store.colors.containsKey('Ali'), isFalse);
      expect(store.emojis.containsKey('Ali'), isFalse);
      expect(store.selected, isNot(contains('Ali')));
      expect(store.favorites, isNot(contains('Ali')));
    });

    test('returns false for non-existent person', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Sara']);
      store.colors['Sara'] = 0xFF000002;

      final result = await store.deletePerson('Ghost');
      expect(result, isFalse);
    });

    test('case-insensitive deletion', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali']);
      store.colors['Ali'] = 0xFF000001;
      store.emojis['Ali'] = '😎';

      final result = await store.deletePerson('ali');
      expect(result, isTrue);
      expect(store.names, isEmpty);
    });
  });

  group('CrewStore.pruneNonFavorites', () {
    test('removes non-favorites, keeps favorites', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali', 'Sara', 'Omar']);
      store.colors['Ali'] = 0xFF000001;
      store.colors['Sara'] = 0xFF000002;
      store.colors['Omar'] = 0xFF000003;
      store.emojis['Ali'] = '😎';
      store.emojis['Sara'] = '🙂';
      store.emojis['Omar'] = '🍔';
      store.favorites.add('Ali');
      store.favorites.add('Sara');

      await store.pruneNonFavorites();

      expect(store.names, contains('Ali'));
      expect(store.names, contains('Sara'));
      expect(store.names, isNot(contains('Omar')));
      expect(store.colors.containsKey('Omar'), isFalse);
      expect(store.emojis.containsKey('Omar'), isFalse);
    });

    test('removes all when no favorites', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali', 'Sara']);
      store.colors['Ali'] = 0xFF000001;
      store.colors['Sara'] = 0xFF000002;
      store.emojis['Ali'] = '😎';
      store.emojis['Sara'] = '🙂';

      await store.pruneNonFavorites();

      expect(store.names, isEmpty);
      expect(store.colors, isEmpty);
      expect(store.emojis, isEmpty);
    });
  });

  group('CrewStore.toggleFavorite', () {
    test('adds and removes favorites', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali']);
      store.colors['Ali'] = 0xFF000001;

      expect(store.isFavorite('Ali'), isFalse);
      await store.toggleFavorite('Ali');
      expect(store.isFavorite('Ali'), isTrue);
      await store.toggleFavorite('Ali');
      expect(store.isFavorite('Ali'), isFalse);
    });
  });

  group('CrewStore.toggleSelect', () {
    test('selects and deselects', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali', 'Sara']);
      store.colors['Ali'] = 0xFF000001;
      store.colors['Sara'] = 0xFF000002;

      store.selected.add('Ali');
      final deselected = store.toggleSelect('Ali');
      expect(deselected, isTrue);
      expect(store.selected, isNot(contains('Ali')));

      final selected = store.toggleSelect('Sara');
      expect(selected, isTrue);
      expect(store.selected, contains('Sara'));
    });
  });

  group('CrewStore.buildSelectedPeople', () {
    test('builds Person list from selected names', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali', 'Sara', 'Omar']);
      store.colors['Ali'] = 0xFF000001;
      store.colors['Sara'] = 0xFF000002;
      store.colors['Omar'] = 0xFF000003;
      store.emojis['Ali'] = '😎';
      store.emojis['Sara'] = '🙂';
      store.emojis['Omar'] = '🍔';
      store.selected.addAll(['Ali', 'Sara']);

      final people = store.buildSelectedPeople(null);
      expect(people.length, 2);
      expect(people[0].name, 'Ali');
      expect(people[1].name, 'Sara');
    });

    test('carries over prior session data via copyWith', () async {
      final store = CrewStore.instance;
      store.names.addAll(['Ali']);
      store.colors['Ali'] = 0xFF000001;
      store.emojis['Ali'] = '😎';
      store.selected.add('Ali');

      final prior = OrderSession(
        id: 's', createdAt: DateTime.now(),
        people: const [Person(id: 'p_old', name: 'Ali', emoji: '🎉', colorValue: 0xFF999999)],
        lines: const [],
      );
      final people = store.buildSelectedPeople(prior);
      expect(people.length, 1);
      // Should use prior ID but updated color/emoji
      expect(people[0].id, 'p_old');
      expect(people[0].colorValue, 0xFF000001);
      expect(people[0].emoji, '😎');
    });
  });

  group('CrewStore helpers', () {
    test('colorFor falls back to palette index', () {
      final store = CrewStore.instance;
      expect(store.colorFor('Unknown', 0), isA<int>());
    });

    test('emojiFor falls back to random emoji', () {
      final store = CrewStore.instance;
      final emoji = store.emojiFor('Unknown');
      expect(emoji, isNotEmpty);
    });

    test('hasEmoji checks case-insensitively', () {
      final store = CrewStore.instance;
      store.emojis['Ali'] = '😎';
      expect(store.hasEmoji('Ali'), isTrue);
      expect(store.hasEmoji('ali'), isTrue);
      expect(store.hasEmoji('Omar'), isFalse);
    });

    test('isDefault rejects known default names', () {
      final store = CrewStore.instance;
      // isDefault returns true only for names in the hardcoded defaults list.
      expect(store.isDefault(''), isFalse);
      expect(store.isDefault('NonExistentPerson123'), isFalse);
    });
  });
}
