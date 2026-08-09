import 'package:flutter/material.dart';

import '../screens/add_orders_page.dart';
import '../screens/add_user_page.dart';
import '../screens/changelog_page.dart';
import '../screens/history_page.dart';
import '../screens/homepage.dart';
import '../screens/output_history_page.dart';
import '../screens/privacy_page.dart';
import '../screens/settings_page.dart';

/// The route the app opens on (mirrors [HomePage.route]).
const String appInitialRoute = HomePage.route;

/// App named routes. Each page owns its own `route` constant — this is just
/// the single registry that wires them into [MaterialApp].
final Map<String, WidgetBuilder> appRoutes = {
  HomePage.route: (_) => const HomePage(),
  AddUserPage.route: (_) => const AddUserPage(),
  AddOrdersPage.route: (_) => const AddOrdersPage(),
  OutputHistoryPage.route: (_) => const OutputHistoryPage(),
  HistoryPage.route: (_) => const HistoryPage(),
  SettingsPage.route: (_) => const SettingsPage(),
  PrivacyPage.route: (_) => const PrivacyPage(),
  ChangelogPage.route: (_) => const ChangelogPage(),
};
