import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_navigator.dart';
import 'core/bootstrap.dart';
import 'core/changelog.dart';

void main() {
  runZonedGuarded(() async {
    await bootstrap();
    runApp(const App101());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppNavigator.key.currentContext;
      if (ctx != null) maybeShowWhatsNew(ctx);
    });
  }, (error, stack) {
    // In production this would report to a crash service.
    Zone.current.print(error.toString());
  });
}
