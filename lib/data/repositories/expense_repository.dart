// lib/data/repositories/expense_repository.dart
import 'package:isar_community/isar.dart';
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
      case ExpenseType.fixed:
      case ExpenseType.monthly:
        return true;
      case ExpenseType.periodic:
        if (e.startDate == null) return true;
        final start = e.startDate!;
        final startMonth = DateTime(start.year, start.month);
        final freq = e.notifyDaysBefore.abs();
        if (freq == 0) return true;
        final diffMonths = (target.year - startMonth.year) * 12 + (target.month - startMonth.month);
        if (diffMonths < 0) return false;
        if (e.installments != null) {
          final totalMonths = e.installments! * freq;
          final endMonth = DateTime(start.year, start.month + totalMonths);
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
    return list.where((e) => !e.paidMonths.contains(key)).fold<double>(0.0, (sum, e) => sum + e.amount);
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
    final all = await getAll();
    return all.fold<double>(0.0, (sum, e) => sum + e.amount);
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

  // ── SEED ──

  Future<void> seedIfEmpty() async {
    final count = await _isar.expenses.count();
    if (count > 0) return;

    final seeds = [
      _seedExpense('Renda', 'Casa', 750.0, ExpenseType.fixed, 1),
      _seedExpense('Luz', 'Serviço', 45.0, ExpenseType.monthly, 5),
      _seedExpense('Água', 'Serviço', 30.0, ExpenseType.monthly, 10),
      _seedExpense('Gás', 'Serviço', 25.0, ExpenseType.monthly, 12),
      _seedExpense('Internet', 'Serviço', 35.0, ExpenseType.monthly, 15),
      _seedExpense('Telemóvel', 'Serviço', 20.0, ExpenseType.monthly, 15),
      _seedExpense('Seguro carro', 'Veículo', 85.0, ExpenseType.periodic, 1),
      _seedExpense('Combustível', 'Veículo', 120.0, ExpenseType.monthly, 20),
      _seedExpense('Ginásio', 'Saúde', 30.0, ExpenseType.monthly, 5),
      _seedExpense('Crédito habitação', 'Crédito', 450.0, ExpenseType.periodic, 5),
    ];

    await _isar.writeTxn(() => _isar.expenses.putAll(seeds));
  }

  Expense _seedExpense(
    String name,
    String category,
    double amount,
    ExpenseType type,
    int dueDay,
  ) {
    return Expense()
      ..name = name
      ..category = category
      ..amount = amount
      ..type = type
      ..dueDay = dueDay
      ..isPaid = false
      ..notifyDaysBefore = 1
      ..isActive = true
      ..createdAt = DateTime.now();
  }
}
