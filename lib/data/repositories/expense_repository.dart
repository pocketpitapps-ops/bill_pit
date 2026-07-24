// lib/data/repositories/expense_repository.dart
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final Isar _isar;

  ExpenseRepository(this._isar);

  // ── CRUD ──

  Future<int> create(Expense expense) async {
    expense.createdAt = DateTime.now();
    expense.updatedAt = DateTime.now();
    return _isar.writeTxnSync(() => _isar.expenses.putSync(expense));
  }

  Future<void> update(Expense expense) async {
    expense.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.expenses.put(expense));
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.expenses.delete(id));
  }

  Future<void> deleteAll() async {
    await _isar.writeTxn(() => _isar.expenses.clear());
  }

  Future<void> togglePaid(int id, {bool? paid}) async {
    final expense = await _isar.expenses.get(id);
    if (expense == null) return;
    expense.isPaid = paid ?? !expense.isPaid;
    expense.paidDate = expense.isPaid ? DateTime.now() : null;
    expense.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.expenses.put(expense));
  }

  Future<void> togglePaidMonth(int id, int month, int year) async {
    final expense = await _isar.expenses.get(id);
    if (expense == null) return;
    final key = Expense.monthKey(month, year);
    final list = List<int>.from(expense.paidMonths);
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.add(key);
    }
    expense.paidMonths = list;
    expense.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.expenses.put(expense));
  }

  Future<void> toggleSkipMonth(int id, int month, int year) async {
    final expense = await _isar.expenses.get(id);
    if (expense == null) return;
    final key = Expense.monthKey(month, year);
    final list = List<int>.from(expense.skippedMonths);
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.add(key);
    }
    expense.skippedMonths = list;
    expense.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.expenses.put(expense));
  }

  // ── QUERIES ──

  Future<Expense?> getById(int id) async {
    return _isar.expenses.get(id);
  }

  Future<List<Expense>> getAll() async {
    return _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .sortByDueDay()
        .findAll();
  }

  Future<List<Expense>> getByMonth(int month, int year) async {
    final all = await _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .sortByDueDay()
        .findAll();

    return all.where((e) => _isRelevantToMonth(e, month, year)).toList();
  }

  bool _isRelevantToMonth(Expense e, int month, int year) {
    final target = DateTime(year, month);
    switch (e.type) {
      case ExpenseType.recurring:
        if (e.startDate != null) {
          final startMonth = DateTime(e.startDate!.year, e.startDate!.month);
          if (target.isBefore(startMonth)) return false;
        }
        final freq = e.frequency ?? 1;
        if (freq <= 0) return true;
        if (e.startDate == null) return true;
        final startMonth = DateTime(e.startDate!.year, e.startDate!.month);
        final diffMonths = (target.year - startMonth.year) * 12 + (target.month - startMonth.month);
        if (diffMonths < 0) return false;
        if (e.installments != null) {
          final totalMonths = e.installments! * freq;
          final endMonth = DateTime(e.startDate!.year, e.startDate!.month + totalMonths);
          if (target.isAfter(DateTime(endMonth.year, endMonth.month))) return false;
        } else if (e.endDate != null) {
          if (target.isAfter(DateTime(e.endDate!.year, e.endDate!.month))) return false;
        }
        return diffMonths % freq == 0;
      case ExpenseType.unique:
        if (e.startDate == null) return true;
        return e.startDate!.year == year && e.startDate!.month == month;
    }
  }

  Future<double> unpaidTotalByMonth(int month, int year) async {
    final list = await getByMonth(month, year);
    final key = Expense.monthKey(month, year);
    return list.where((e) => !e.paidMonths.contains(key)).fold<double>(0.0, (sum, e) => sum + e.effectiveAmount(month, year));
  }

  Future<List<Expense>> getPaid() async {
    return _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .isPaidEqualTo(true)
        .sortByPaidDateDesc()
        .findAll();
  }

  Future<List<Expense>> getUnpaid() async {
    return _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .isPaidEqualTo(false)
        .sortByDueDay()
        .findAll();
  }

  Future<List<Expense>> getByCategory(String category) async {
    return _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .categoryEqualTo(category)
        .sortByDueDay()
        .findAll();
  }

  // ── STATS ──

  Future<double> totalByMonth(int month, int year) async {
    final all = await getByMonth(month, year);
    return all.fold<double>(0.0, (sum, e) => sum + e.effectiveAmount(month, year));
  }

  Future<double> paidTotal() async {
    final list = await getPaid();
    return list.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<double> unpaidTotal() async {
    final list = await getUnpaid();
    return list.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<Map<String, double>> totalByCategory() async {
    final all = await getAll();
    final map = <String, double>{};
    for (final e in all) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // ── CATEGORY HELPERS ──

  Future<int> renameCategory(String oldName, String newName) async {
    final all = await _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .categoryEqualTo(oldName)
        .findAll();
    if (all.isEmpty) return 0;
    await _isar.writeTxn(() async {
      for (final e in all) {
        e.category = newName;
        e.updatedAt = DateTime.now();
        await _isar.expenses.put(e);
      }
    });
    return all.length;
  }

  Future<int> moveCategory(String fromCategory, String toCategory) async {
    final all = await _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .categoryEqualTo(fromCategory)
        .findAll();
    if (all.isEmpty) return 0;
    await _isar.writeTxn(() async {
      for (final e in all) {
        e.category = toCategory;
        e.updatedAt = DateTime.now();
        await _isar.expenses.put(e);
      }
    });
    return all.length;
  }

  Future<int> countByCategory(String category) async {
    return _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .categoryEqualTo(category)
        .count();
  }

  // ── SEED ──

  Future<void> seedIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_seen_onboarding') == true) return;

    final count = await _isar.expenses.count();
    if (count > 0) return;

    final seeds = [
      _seedExpense('Renda', 'Casa', 750.0, ExpenseType.recurring, 1, isVariable: false, frequency: 1),
      _seedExpense('Luz', 'Electricidade', 45.0, ExpenseType.recurring, 5, isVariable: true, frequency: 1),
      _seedExpense('Água', 'Água', 30.0, ExpenseType.recurring, 10, isVariable: true, frequency: 1),
      _seedExpense('Gás', 'Gás', 25.0, ExpenseType.recurring, 12, isVariable: true, frequency: 1),
      _seedExpense('Internet', 'Subscrições', 35.0, ExpenseType.recurring, 15, isVariable: false, frequency: 1),
      _seedExpense('Telemóvel', 'Subscrições', 20.0, ExpenseType.recurring, 15, isVariable: false, frequency: 1),
      _seedExpense('Seguro carro', 'Veículo', 85.0, ExpenseType.recurring, 1, isVariable: false, frequency: 1),
      _seedExpense('Combustível', 'Veículo', 120.0, ExpenseType.recurring, 20, isVariable: true, frequency: 1),
      _seedExpense('Ginásio', 'Saúde', 30.0, ExpenseType.recurring, 5, isVariable: false, frequency: 1),
      _seedExpense('Crédito habitação', 'Crédito', 450.0, ExpenseType.recurring, 5, isVariable: false, frequency: 1),
    ];

    await _isar.writeTxn(() => _isar.expenses.putAll(seeds));
  }

  Expense _seedExpense(
    String name,
    String category,
    double amount,
    ExpenseType type,
    int dueDay, {
    bool isVariable = false,
    int frequency = 1,
  }) {
    return Expense()
      ..name = name
      ..category = category
      ..amount = amount
      ..type = type
      ..isVariable = isVariable
      ..dueDay = dueDay
      ..frequency = frequency
      ..isPaid = false
      ..reminderDays = 3
      ..isActive = true
      ..amountConfirmed = false
      ..createdAt = DateTime.now();
  }
}
