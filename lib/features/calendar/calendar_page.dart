import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/services/category_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
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

  Color? _dayColor(List<Expense> dayExpenses, int month, int year) {
    if (dayExpenses.isEmpty) return null;
    final key = Expense.monthKey(month, year);
    final now = DateTime.now();
    final activeExpenses = dayExpenses.where((e) => !e.skippedMonths.contains(key)).toList();
    if (activeExpenses.isEmpty) return Colors.grey;
    final allPaid = activeExpenses.every((e) => e.paidMonths.contains(key));
    final effectiveDay = activeExpenses.first.effectiveDueDay(month, year);
    final isPast = DateTime(year, month, effectiveDay).isBefore(DateTime(now.year, now.month, now.day));

    if (allPaid) return Colors.green;
    if (isPast) return Colors.red;
    return Colors.orange;
  }

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
                  final effectiveDay = e.effectiveDueDay(month, year);
                  byDay.putIfAbsent(effectiveDay, () => []).add(e);
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
                    final key = Expense.monthKey(month, year);
                    final activeDayExpenses = dayExpenses.where((e) => !e.skippedMonths.contains(key)).toList();
                    final total = activeDayExpenses.fold<double>(0, (s, e) => s + e.amount);
                    final color = _dayColor(dayExpenses, month, year);
                    final hasAnyExpenses = dayExpenses.isNotEmpty;

                    return GestureDetector(
                      onTap: () => _showDayExpenses(context, day, dayExpenses, month, year),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : hasAnyExpenses && color != null
                                  ? color.withValues(alpha: 0.15)
                                  : null,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : hasAnyExpenses && color != null
                                    ? color
                                    : Colors.transparent,
                            width: hasAnyExpenses || isToday ? 1.5 : 0,
                          ),
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
                            if (hasAnyExpenses) ...[
                              const SizedBox(height: 2),
                              if (activeDayExpenses.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${total.toStringAsFixed(0)}€',
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
                                  ),
                                )
                              else
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
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

  void _showDayExpenses(BuildContext context, int day, List<Expense> expenses, int month, int year) {
    final catService = context.read<CategoryService>();
    final repo = context.read<ExpenseRepository>();
    final monthKey = Expense.monthKey(month, year);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: expenses.isEmpty ? 0.3 : 0.5,
        minChildSize: 0.2,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dia $day',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseFormPage(initialDueDay: day),
                      ),
                    );
                    if (result == true) setState(() {});
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Nova despesa',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Sem despesas neste dia.')),
              )
            else
              ...expenses.map((e) {
                final catData = catService.findByName(e.category);
                final paid = e.paidMonths.contains(monthKey);
                final skipped = e.skippedMonths.contains(monthKey);
                final effectiveDay = e.effectiveDueDay(month, year);
                final isPast = DateTime(year, month, effectiveDay).isBefore(DateTime.now());
                final color = skipped
                    ? Colors.grey
                    : (paid ? Colors.green : (isPast ? Colors.red : Colors.orange));
                final isRecurring = e.type == ExpenseType.recurring;
                final showSkip = isRecurring && !paid;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (catData?.color ?? Colors.grey).withValues(alpha: skipped ? 0.05 : 0.15),
                      child: Icon(
                        catData?.icon ?? Icons.more_horiz,
                        color: skipped ? Colors.grey : (catData?.color ?? Colors.grey),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      e.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: skipped ? TextDecoration.lineThrough : null,
                        color: skipped ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(
                      skipped
                          ? '${e.amount.toStringAsFixed(2)}€ · Ignorado'
                          : '${e.amount.toStringAsFixed(2)}€ · ${expenseTypeLabels[e.type]}',
                      style: TextStyle(color: skipped ? Colors.grey : null),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showSkip)
                          IconButton(
                            icon: Icon(
                              skipped ? Icons.replay : Icons.remove_circle_outline,
                              color: skipped ? Colors.orange : Colors.grey,
                              size: 22,
                            ),
                            tooltip: skipped ? 'Repor despesa' : 'Ignorar este mês',
                            onPressed: () async {
                              await repo.toggleSkipMonth(e.id, month, year);
                              if (ctx.mounted) Navigator.pop(ctx);
                              setState(() {});
                            },
                          ),
                        if (!skipped)
                          Icon(
                            paid ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: color,
                          ),
                      ],
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: e)),
                      );
                      if (result == true) setState(() {});
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
