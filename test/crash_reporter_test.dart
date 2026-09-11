import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:app_101/core/bootstrap.dart';
import 'package:app_101/core/crash_reporter.dart';

class RecordingCrashReporter implements CrashReporter {
  final errors = <({Object error, StackTrace stack, String source})>[];

  @override
  Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    required String source,
  }) async {
    errors.add((error: error, stack: stackTrace, source: source));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crash reporting is disabled without a DSN', () async {
    final reporter = await createCrashReporter(dsn: '');
    expect(reporter, isA<NoopCrashReporter>());
  });

  test('Flutter errors are forwarded through the abstraction', () async {
    final reporter = RecordingCrashReporter();
    await bootstrap(crashReporter: reporter);
    final error = FlutterErrorDetails(
      exception: StateError('test crash'),
      stack: StackTrace.current,
    );

    FlutterError.onError!(error);
    await Future<void>.delayed(Duration.zero);

    expect(reporter.errors, hasLength(1));
    expect(reporter.errors.single.source, 'flutter');
    expect(reporter.errors.single.error, isA<StateError>());
  });
}
