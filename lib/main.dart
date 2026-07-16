// lib/main.dart
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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

  runApp(
    Provider<ExpenseRepository>.value(
      value: repo,
      child: const BillPitApp(),
    ),
  );
}
