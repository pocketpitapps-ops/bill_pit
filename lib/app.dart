// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: brightness,
          statusBarIconBrightness: brightness == Brightness.light ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: brightness == Brightness.light ? Colors.white : const Color(0xFF1E293B),
          systemNavigationBarIconBrightness: brightness == Brightness.light ? Brightness.dark : Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ));
        return child!;
      },
    );
  }
}
