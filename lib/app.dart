// lib/app.dart
import 'package:flutter/material.dart';
import 'core/theme/bill_pit_theme.dart';
import 'features/home/home_page.dart';

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
      home: const HomePage(),
    );
  }
}
