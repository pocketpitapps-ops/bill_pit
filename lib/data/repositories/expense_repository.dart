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
    return _isar.expenses
        .where()
        .filter()
        .isActiveEqualTo(true)
        .dueDayIsNotNull()
        .dueDayGreaterThan(0)
        .dueDayLessThan(32)
        .sortByDueDay()
        .findAll();
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
      _seedExpense('Luz', 'Serviços', 45.0, ExpenseType.monthly, 5),
      _seedExpense('Água', 'Serviços', 30.0, ExpenseType.monthly, 10),
      _seedExpense('Gás', 'Serviços', 25.0, ExpenseType.monthly, 12),
      _seedExpense('Internet', 'Serviços', 35.0, ExpenseType.monthly, 15),
      _seedExpense('Telemóvel', 'Serviços', 20.0, ExpenseType.monthly, 15),
      _seedExpense('Seguro carro', 'Transporte', 85.0, ExpenseType.periodic, 1),
      _seedExpense('Combustível', 'Transporte', 120.0, ExpenseType.monthly, 20),
      _seedExpense('Ginásio', 'Saúde', 30.0, ExpenseType.monthly, 5),
      _seedExpense('Netflx', 'Lazer', 13.0, ExpenseType.monthly, 22),
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
      ..notifyDaysBefore = 3
      ..isActive = true
      ..createdAt = DateTime.now();
  }
}
