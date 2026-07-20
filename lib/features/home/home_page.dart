import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/category_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/theme/bill_pit_theme.dart';
import '../calendar/calendar_page.dart';
import '../expenses/expenses_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _keys = List.generate(4, (_) => UniqueKey());

  void _refreshAll() {
    setState(() {
      for (var i = 0; i < _keys.length; i++) {
        _keys[i] = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(key: _keys[0], onRefresh: _refreshAll),
          ExpensesPage(key: _keys[1]),
          CalendarPage(key: _keys[2]),
          SettingsPage(key: _keys[3]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Despesas'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendário'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Definições'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DashboardTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExpenseRepository>();
    final catService = context.watch<CategoryService>();

    return SafeArea(
      child: FutureBuilder<List<Expense>>(
        future: repo.getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final expenses = snapshot.data!;
          if (expenses.isEmpty) {
            return const Center(child: Text('Sem despesas ainda.'));
          }

          final grandTotal = expenses.fold<double>(0, (s, e) => s + e.amount);
          final paidTotal = expenses.where((e) => e.isPaid).fold<double>(0, (s, e) => s + e.amount);
          final unpaidTotal = grandTotal - paidTotal;
          final paidCount = expenses.where((e) => e.isPaid).length;

          final byCategory = <String, double>{};
          for (final e in expenses) {
            byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
          }
          final sortedCats = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final upcoming = expenses.where((e) {
            if (e.isPaid) return false;
            if (e.type == ExpenseType.periodic && e.startDate != null) {
              final freq = e.notifyDaysBefore.abs() > 0 ? e.notifyDaysBefore.abs() : 1;
              final start = e.startDate!;
              var next = DateTime(start.year, start.month, start.day);
              while (next.isBefore(today)) {
                next = DateTime(next.year, next.month + freq, next.day);
              }
              final diff = next.difference(today).inDays;
              return diff >= 0 && diff <= 7;
            }
            if (e.dueDay == null) return false;
            final effectiveDay = e.effectiveDueDay(now.month, now.year);
            final dueDate = DateTime(now.year, now.month, effectiveDay);
            final diff = dueDate.difference(today).inDays;
            return diff >= 0 && diff <= 7;
          }).toList()..sort((a, b) {
            DateTime dueA = _nextDue(a, today);
            DateTime dueB = _nextDue(b, today);
            return dueA.compareTo(dueB);
          });

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BillPitTheme.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long, color: BillPitTheme.primaryLight, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Pit',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        _monthLabel(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _SummaryCard(title: 'Total', value: '${grandTotal.toStringAsFixed(2)}€', color: BillPitTheme.primaryLight),
                  const SizedBox(width: 12),
                  _SummaryCard(title: 'Pago', value: '${paidTotal.toStringAsFixed(2)}€', color: BillPitTheme.paid),
                  const SizedBox(width: 12),
                  _SummaryCard(title: 'Pendente', value: '${unpaidTotal.toStringAsFixed(2)}€', color: BillPitTheme.unpaid),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: grandTotal > 0 ? paidTotal / grandTotal : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$paidCount/${expenses.length}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (upcoming.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Próximos 7 dias', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text('${upcoming.length} pendentes', style: TextStyle(fontSize: 12, color: BillPitTheme.unpaid)),
                  ],
                ),
                const SizedBox(height: 8),
                ...upcoming.map((e) {
                  final catData = catService.findByName(e.category);
                  final nextDue = _nextDue(e, today);
                  final diff = nextDue.difference(today).inDays;
                  final label = diff == 0 ? 'Hoje' : diff == 1 ? 'Amanhã' : 'Em $diff dias';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: (catData?.color ?? Colors.grey).withValues(alpha: 0.15),
                        child: Icon(catData?.icon ?? Icons.more_horiz, color: catData?.color ?? Colors.grey, size: 18),
                      ),
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(label, style: TextStyle(color: diff <= 1 ? BillPitTheme.unpaid : Colors.grey.shade600, fontSize: 12)),
                      trailing: Text('${e.amount.toStringAsFixed(2)}€', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              Text('Por Categoria', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sortedCats.map((entry) {
                      final catData = catService.findByName(entry.key);
                      final pct = grandTotal > 0 ? (entry.value / grandTotal * 100) : 0.0;
                      return PieChartSectionData(
                        value: entry.value,
                        color: catData?.color ?? Colors.grey,
                        radius: 50,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...sortedCats.map((entry) {
                final catData = catService.findByName(entry.key);
                final pct = grandTotal > 0 ? entry.value / grandTotal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(catData?.icon ?? Icons.more_horiz, color: catData?.color ?? Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('${entry.value.toStringAsFixed(2)}€', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(catData?.color ?? Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text('Pago vs Pendente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: grandTotal * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: paidTotal,
                            color: BillPitTheme.paid,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: unpaidTotal,
                            color: BillPitTheme.unpaid,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(color: BillPitTheme.paid, label: 'Pago'),
                  const SizedBox(width: 24),
                  _Legend(color: BillPitTheme.unpaid, label: 'Pendente'),
                ],
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  String _monthLabel() {
    final now = DateTime.now();
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }
}

DateTime _nextDue(Expense e, DateTime today) {
  if (e.type == ExpenseType.periodic && e.startDate != null) {
    final freq = e.notifyDaysBefore.abs() > 0 ? e.notifyDaysBefore.abs() : 1;
    final start = e.startDate!;
    var next = DateTime(start.year, start.month, start.day);
    while (next.isBefore(today)) {
      next = DateTime(next.year, next.month + freq, next.day);
    }
    return next;
  }
  if (e.dueDay != null) {
    final effectiveDay = e.effectiveDueDay(today.month, today.year);
    return DateTime(today.year, today.month, effectiveDay);
  }
  return DateTime(today.year, today.month, today.day);
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
