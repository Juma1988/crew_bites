import 'package:sentry_flutter/sentry_flutter.dart';

/// Receives uncaught application errors without coupling the app bootstrap to
/// a particular crash reporting vendor.
abstract interface class CrashReporter {
  Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    required String source,
  });
}

/// Reporting must never become a second uncaught error in the app.
Future<void> reportCrashSafely(
  CrashReporter reporter,
  Object error,
  StackTrace stackTrace, {
  required String source,
}) async {
  try {
    await reporter.reportError(error, stackTrace, source: source);
  } catch (_) {
    // Crash reporting is best effort and must not affect app behavior.
  }
}

/// Keeps the app fully offline when reporting has not been configured.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    required String source,
  }) async {}
}

class SentryCrashReporter implements CrashReporter {
  const SentryCrashReporter._();

  /// Creates a reporter only after Sentry has been initialized with [dsn].
  static Future<SentryCrashReporter> initialize(String dsn) async {
    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.sendDefaultPii = false;
    });
    return const SentryCrashReporter._();
  }

  @override
  Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    required String source,
  }) async {
    await Sentry.captureException(error, stackTrace: stackTrace, withScope: (
      scope,
    ) {
      scope.setTag('error_source', source);
    });
  }
}

/// Builds the configured reporter. An absent DSN intentionally selects the
/// no-op implementation and performs no network setup.
Future<CrashReporter> createCrashReporter({String? dsn}) async {
  final configuredDsn =
      dsn ?? const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  if (configuredDsn.trim().isEmpty) return const NoopCrashReporter();
  return SentryCrashReporter.initialize(configuredDsn.trim());
}
