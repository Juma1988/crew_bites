import 'dart:async';

import 'package:flutter/material.dart';

import 'app_settings.dart';

/// Async startup: binding init, crash handlers, settings load. Returns once
/// the app is ready to mount — [main] then calls runApp.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
  await AppSettings.instance.load();
}
