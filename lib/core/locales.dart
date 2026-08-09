import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Locales the app ships with (order matters — first is the fallback).
const List<Locale> appSupportedLocales = [Locale('en'), Locale('ar')];

/// Localization delegates wired into [MaterialApp].
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
