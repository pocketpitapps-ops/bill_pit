import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'core/services/notification_service.dart';
import 'data/models/expense.dart';
import 'data/repositories/expense_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ExpenseSchema],
    directory: dir.path,
    name: 'bill_pit',
  );

  final repo = ExpenseRepository(isar);
  await repo.seedIfEmpty();

  final notificationService = NotificationService(repo: repo);
  await notificationService.init();
  await NotificationService.initWorkmanager();

  runApp(
    MultiProvider(
      providers: [
        Provider<ExpenseRepository>.value(value: repo),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const BillPitApp(),
    ),
  );
}
