import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_101/core/services/shared_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves the platform preferences instance', () async {
    SharedPreferences.setMockInitialValues({'service_key': 'value'});

    final prefs = await SharedPreferencesService.instance.get();

    expect(prefs.getString('service_key'), 'value');
  });
}
