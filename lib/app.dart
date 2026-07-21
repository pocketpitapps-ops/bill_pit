// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/bill_pit_theme.dart';
import 'features/intro/splash_intro_page.dart';

class BillPitApp extends StatelessWidget {
  const BillPitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Pit',
      debugShowCheckedModeBanner: false,
      theme: BillPitTheme.light,
      darkTheme: BillPitTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'PT'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'PT'),
        Locale('en', 'US'),
      ],
      home: const SplashIntroPage(),
    );
  }
}
