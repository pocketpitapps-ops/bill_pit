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

  int? dueDay;

  DateTime? startDate;

  DateTime? endDate;

  late bool isPaid;

  DateTime? paidDate;

  late int notifyDaysBefore;

  late bool isActive;

  late DateTime createdAt;

  DateTime? updatedAt;
}

enum ExpenseType {
  fixed,
  monthly,
  periodic,
  unique,
}
