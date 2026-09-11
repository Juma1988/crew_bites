import 'dart:async';

import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'crash_reporter.dart';

/// Async startup: binding init, crash handlers, settings load. Returns once
/// the app is ready to mount — [main] then calls runApp.
Future<CrashReporter> bootstrap({CrashReporter? crashReporter}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final reporter = crashReporter ?? await createCrashReporter();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    unawaited(reportCrashSafely(
      reporter,
      details.exception,
      details.stack ?? StackTrace.empty,
      source: 'flutter',
    ));
  };
  await AppSettings.instance.load();
  return reporter;
}
