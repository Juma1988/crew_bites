import 'package:flutter/material.dart';

import '../core/app_navigator.dart';
import '../core/debug/debug_overlay.dart';
import '../core/locales.dart';
import '../core/routes.dart';
import '../core/states/app_settings.dart';
import '../core/theme.dart';

/// The root [MaterialApp]. Rebuilds on [AppSettings] changes so theme /
/// locale / directionality update live.
class App101 extends StatelessWidget {
  const App101({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        return MaterialApp(
          navigatorKey: AppNavigator.key,
          title: AppTheme.brandName,
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          theme: AppTheme.light(settings.colorPalette),
          darkTheme: AppTheme.dark(settings.colorPalette),
          themeMode: settings.themeMode,
          builder: (context, child) {
            return Directionality(
              textDirection: settings.textDirection,
              child: DebugOverlay(
                enabled: settings.debugOverlayEnabled,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          initialRoute: appInitialRoute,
          routes: appRoutes,
        );
      },
    );
  }
}
