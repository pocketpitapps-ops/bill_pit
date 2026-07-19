import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'core/services/category_service.dart';
import 'core/services/notification_service.dart';
import 'data/models/expense.dart';
import 'data/repositories/expense_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Isar? isar;
  ExpenseRepository? repo;
  CategoryService? categoryService;
  NotificationService? notificationService;

  try {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ExpenseSchema],
      directory: dir.path,
      name: 'bill_pit',
    );

    repo = ExpenseRepository(isar);
    await repo.seedIfEmpty();
  } catch (e) {
    debugPrint('Error initializing Isar: $e');
  }

  try {
    categoryService = CategoryService();
    await categoryService!.load();
  } catch (e) {
    debugPrint('Error loading categories: $e');
    categoryService = CategoryService();
  }

  try {
    if (repo != null) {
      notificationService = NotificationService(repo: repo);
      await notificationService.init();
      await NotificationService.initWorkmanager();
    }
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
    notificationService = null;
  }

  runApp(
    MultiProvider(
      providers: [
        if (repo != null) Provider<ExpenseRepository>.value(value: repo),
        ChangeNotifierProvider<CategoryService>.value(
          value: categoryService ?? CategoryService(),
        ),
        if (notificationService != null)
          Provider<NotificationService>.value(value: notificationService),
      ],
      child: const BillPitApp(),
    ),
  );
}
