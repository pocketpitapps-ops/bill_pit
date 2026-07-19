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

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Ocorreu um erro: ${details.exceptionAsString()}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  };

  Isar? isar;
  ExpenseRepository? repo;

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
    repo = null;
  }

  CategoryService categoryService;
  try {
    categoryService = CategoryService();
    await categoryService.load();
  } catch (e) {
    debugPrint('Error loading categories: $e');
    categoryService = CategoryService();
  }

  NotificationService? notificationService;
  if (repo != null) {
    try {
      notificationService = NotificationService(repo: repo);
      await notificationService.init();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      notificationService = null;
    }
  }

  if (repo != null) {
    runApp(
      MultiProvider(
        providers: [
          Provider<ExpenseRepository>.value(value: repo),
          ChangeNotifierProvider<CategoryService>.value(value: categoryService),
          if (notificationService != null)
            Provider<NotificationService>.value(value: notificationService),
        ],
        child: const BillPitApp(),
      ),
    );

    try {
      await NotificationService.initWorkmanager();
    } catch (e) {
      debugPrint('Error initializing workmanager: $e');
    }
  } else {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível inicializar a base de dados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por favor, reinstale a aplicação.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
