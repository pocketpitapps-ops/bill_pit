import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../services/category_service.dart';

class BackupService {
  static const int currentVersion = 1;

  static Future<String> exportToJson({
    required ExpenseRepository repo,
    required CategoryService catService,
  }) async {
    final expenses = await repo.getAll();
    final categories = catService.categories;
    final prefs = await SharedPreferences.getInstance();

    final expensesJson = expenses.map((e) => {
      'id': e.id,
      'name': e.name,
      'category': e.category,
      'amount': e.amount,
      'type': e.type.index,
      'isVariable': e.isVariable,
      'dueDay': e.dueDay,
      'startDate': e.startDate?.toIso8601String(),
      'endDate': e.endDate?.toIso8601String(),
      'installments': e.installments,
      'frequency': e.frequency,
      'isPaid': e.isPaid,
      'paidDate': e.paidDate?.toIso8601String(),
      'paidMonths': e.paidMonths,
      'reminderDays': e.reminderDays,
      'isActive': e.isActive,
      'amountConfirmed': e.amountConfirmed,
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt?.toIso8601String(),
    }).toList();

    final categoriesJson = categories.map((c) => c.toJson()).toList();

    final settings = <String, dynamic>{};
    for (final key in [
      'monthly_summary_day',
      'monthly_summary_hour',
      'weekly_preview_hour',
      'overdue_days',
      'overdue_hour',
      'default_reminder_days',
    ]) {
      final val = prefs.getInt(key);
      if (val != null) settings[key] = val;
    }

    final backup = {
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'expenses': expensesJson,
      'categories': categoriesJson,
      'settings': settings,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  static Future<void> exportAndShare({
    required ExpenseRepository repo,
    required CategoryService catService,
  }) async {
    final json = await exportToJson(repo: repo, catService: catService);
    final timestamp = DateTime.now().toIso8601String().substring(0, 10);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/bill_pit_backup_$timestamp.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Backup Bill Pit',
    );
  }

  static Future<Map<String, dynamic>?> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final file = File(result.files.first.path!);
    final json = await file.readAsString();
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static Future<ImportResult> restore({
    required Map<String, dynamic> data,
    required ExpenseRepository repo,
    required CategoryService catService,
    required bool deleteExisting,
  }) async {
    final version = data['version'] as int? ?? 0;
    if (version > currentVersion) {
      return ImportResult.error('Versão de backup ($version) não suportada.');
    }

    int expensesImported = 0;
    int categoriesImported = 0;
    int settingsImported = 0;

    if (deleteExisting) {
      await repo.deleteAll();
      await catService.clearAll();
    }

    final categories = data['categories'] as List<dynamic>?;
    if (categories != null) {
      for (final c in categories) {
        final cat = AppCategory.fromJson(c as Map<String, dynamic>);
        if (!catService.nameExists(cat.name)) {
          await catService.addFromBackup(cat);
          categoriesImported++;
        }
      }
    }

    final expenses = data['expenses'] as List<dynamic>?;
    if (expenses != null) {
      for (final e in expenses) {
        final map = e as Map<String, dynamic>;
        final expense = Expense()
          ..name = map['name'] as String
          ..category = map['category'] as String
          ..amount = (map['amount'] as num).toDouble()
          ..type = ExpenseType.values[map['type'] as int]
          ..isVariable = map['isVariable'] as bool? ?? false
          ..dueDay = map['dueDay'] as int?
          ..startDate = map['startDate'] != null ? DateTime.parse(map['startDate'] as String) : null
          ..endDate = map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null
          ..installments = map['installments'] as int?
          ..frequency = map['frequency'] as int?
          ..isPaid = map['isPaid'] as bool? ?? false
          ..paidDate = map['paidDate'] != null ? DateTime.parse(map['paidDate'] as String) : null
          ..paidMonths = (map['paidMonths'] as List<dynamic>?)?.map((e) => e as int).toList() ?? []
          ..reminderDays = map['reminderDays'] as int? ?? 3
          ..isActive = map['isActive'] as bool? ?? true
          ..amountConfirmed = map['amountConfirmed'] as bool? ?? false
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null;
        await repo.create(expense);
        expensesImported++;
      }
    }

    final settings = data['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in settings.entries) {
        if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
          settingsImported++;
        }
      }
    }

    return ImportResult.success(
      expenses: expensesImported,
      categories: categoriesImported,
      settings: settingsImported,
    );
  }
}

class ImportResult {
  final bool success;
  final String? error;
  final int expenses;
  final int categories;
  final int settings;

  ImportResult._({required this.success, this.error, this.expenses = 0, this.categories = 0, this.settings = 0});

  factory ImportResult.success({required int expenses, required int categories, required int settings}) =>
      ImportResult._(success: true, expenses: expenses, categories: categories, settings: settings);

  factory ImportResult.error(String msg) => ImportResult._(success: false, error: msg);
}
