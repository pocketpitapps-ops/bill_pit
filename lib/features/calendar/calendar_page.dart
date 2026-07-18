import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/constants/categories.dart';
import '../expense_form/expense_form_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
  void _nextMonth() => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExpenseRepository>();
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;

    const monthNames = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'Calendário',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                Text(
                  '${monthNames[month - 1]} $year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _WeekdayHeader(),
          const SizedBox(height: 4),
          Expanded(
            child: FutureBuilder<List<Expense>>(
              future: repo.getByMonth(month, year),
              builder: (context, snapshot) {
                final expenses = snapshot.data ?? [];
                final byDay = <int, List<Expense>>{};
                for (final e in expenses) {
                  if (e.dueDay != null) {
                    byDay.putIfAbsent(e.dueDay!, () => []).add(e);
                  }
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: (firstWeekday - 1) + daysInMonth,
                  itemBuilder: (context, index) {
                    final offset = firstWeekday - 1;
                    if (index < offset) return const SizedBox();
                    final day = index - offset + 1;
                    final dayExpenses = byDay[day] ?? [];
                    final isToday = day == DateTime.now().day &&
                        month == DateTime.now().month &&
                        year == DateTime.now().year;
                    final total = dayExpenses.fold<double>(0, (s, e) => s + e.amount);

                    return GestureDetector(
                      onTap: dayExpenses.isNotEmpty ? () => _showDayExpenses(context, day, dayExpenses) : null,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : dayExpenses.isNotEmpty
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                  : null,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                color: isToday ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                            if (dayExpenses.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: dayExpenses.every((e) => e.isPaid)
                                      ? Colors.green
                                      : dayExpenses.any((e) => e.isPaid)
                                          ? Colors.orange
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${total.toStringAsFixed(0)}€',
                                  style: const TextStyle(color: Colors.white, fontSize: 9),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDayExpenses(BuildContext context, int day, List<Expense> expenses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dia $day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...expenses.map((e) {
              final catData = categories.values.firstWhere(
                (c) => c.name == e.category,
                orElse: () => const CategoryData('Outro', Icons.more_horiz, Colors.grey),
              );
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: catData.color.withValues(alpha: 0.15),
                    child: Icon(catData.icon, color: catData.color, size: 20),
                  ),
                  title: Text(e.name),
                  subtitle: Text('${e.amount.toStringAsFixed(2)}€ · ${expenseTypeLabels[e.type]}'),
                  trailing: Icon(
                    e.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: e.isPaid ? Colors.green : Colors.red,
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: e)),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
