import 'package:isar_community/isar.dart';

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String name;

  late String category;

  late double amount;

  @enumerated
  late ExpenseType type;

  late bool isVariable;

  int? dueDay;

  DateTime? startDate;

  DateTime? endDate;

  int? installments;

  int? frequency;

  late bool isPaid;

  DateTime? paidDate;

  List<int> paidMonths = [];

  List<int> skippedMonths = [];

  late int reminderDays;

  late bool isActive;

  late bool amountConfirmed;

  late DateTime createdAt;

  DateTime? updatedAt;

  bool isPaidInMonth(int month, int year) {
    return paidMonths.contains(year * 100 + month);
  }

  bool isSkippedInMonth(int month, int year) {
    return skippedMonths.contains(year * 100 + month);
  }

  static int monthKey(int month, int year) => year * 100 + month;

  static DateTime nextBusinessDay(DateTime date) {
    if (date.weekday == DateTime.saturday) return date.add(const Duration(days: 2));
    if (date.weekday == DateTime.sunday) return date.add(const Duration(days: 1));
    return date;
  }

  int effectiveDueDay(int month, int year) {
    final d = dueDay ?? startDate?.day ?? 1;
    final maxDay = DateTime(year, month + 1, 0).day;
    final date = DateTime(year, month, d.clamp(1, maxDay));
    return nextBusinessDay(date).day;
  }
}

enum ExpenseType {
  recurring,
  unique,
}
