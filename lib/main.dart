import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/states/app_settings.dart';
import 'core/theme.dart';
import 'screens/add_orders_page.dart';
import 'screens/add_user_page.dart';
import 'screens/history_page.dart';
import 'screens/homepage.dart';
import 'screens/output_history_page.dart';
import 'screens/privacy_page.dart';
import 'screens/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(const App101());
}

/// Shared navigator so settings rebuilds keep the route stack.
abstract final class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

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
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(settings.colorPalette),
          darkTheme: AppTheme.dark(settings.colorPalette),
          themeMode: settings.themeMode,
          builder: (context, child) {
            return Directionality(
              textDirection: settings.textDirection,
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: HomePage.route,
          routes: {
            HomePage.route: (_) => const HomePage(),
            AddUserPage.route: (_) => const AddUserPage(),
            AddOrdersPage.route: (_) => const AddOrdersPage(),
            OutputHistoryPage.route: (_) => const OutputHistoryPage(),
            HistoryPage.route: (_) => const HistoryPage(),
            SettingsPage.route: (_) => const SettingsPage(),
            PrivacyPage.route: (_) => const PrivacyPage(),
          },
        );
      },
    );
  }
}
