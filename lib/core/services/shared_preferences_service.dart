import 'package:shared_preferences/shared_preferences.dart';

/// Central access point for the app's local preferences store.
///
/// Callers that already have a [SharedPreferences] instance may continue to
/// pass it to stores. This service only owns resolving the default instance.
final class SharedPreferencesService {
  SharedPreferencesService._();

  static final SharedPreferencesService instance = SharedPreferencesService._();

  Future<SharedPreferences> get() => SharedPreferences.getInstance();
}
