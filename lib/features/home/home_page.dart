import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/constants/categories.dart';
import '../expense_form/expense_form_page.dart';
import '../calendar/calendar_page.dart';
import '../categories/categories_page.dart';
import '../statistics/statistics_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  Key _homeKey = UniqueKey();
  Key _calendarKey = UniqueKey();
  Key _categoriesKey = UniqueKey();
  Key _statsKey = UniqueKey();

  void _refreshAll() {
    setState(() {
      _homeKey = UniqueKey();
      _calendarKey = UniqueKey();
      _categoriesKey = UniqueKey();
      _statsKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(key: _homeKey, onRefresh: _refreshAll),
          CalendarPage(key: _calendarKey),
          CategoriesPage(key: _categoriesKey),
          StatisticsPage(key: _statsKey),
          SettingsPage(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
                );
                if (result == true) _refreshAll();
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendário'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categorias'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Gráficos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Definições'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HomeTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExpenseRepository>();

    return SafeArea(
      child: FutureBuilder<List<Expense>>(
        future: repo.getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final expenses = snapshot.data!;
          final paidCount = expenses.where((e) => e.isPaid).length;
          final total = expenses.fold<double>(0, (s, e) => s + e.amount);
          final paidTotal = expenses.where((e) => e.isPaid).fold<double>(0, (s, e) => s + e.amount);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Bill Pit',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    _monthLabel(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              if (expenses.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    Text('${total.toStringAsFixed(2)}€',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Pago', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    Text('${paidTotal.toStringAsFixed(2)}€',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: total > 0 ? paidTotal / total : 0,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(Colors.green),
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Text('$paidCount/${expenses.length} despesas pagas',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (expenses.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Despesas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (expenses.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Sem despesas ainda.\nToca em + para adicionar.'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ExpenseTile(
                      expense: expenses[index],
                      onRefresh: onRefresh,
                    ),
                    childCount: expenses.length,
                  ),
                ),
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

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onRefresh;
  const _ExpenseTile({required this.expense, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ExpenseRepository>();
    final paid = expense.isPaid;
    final amountStr = '${expense.amount.toStringAsFixed(2)}€';
    final dueLabel = expense.dueDay != null ? 'Dia ${expense.dueDay}' : '';

    final catData = categories.values.firstWhere(
      (c) => c.name == expense.category,
      orElse: () => const CategoryData('Outro', Icons.more_horiz, Colors.grey),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: catData.color.withValues(alpha: 0.15),
          child: Icon(catData.icon, color: catData.color, size: 20),
        ),
        title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$dueLabel · ${expense.category}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(amountStr, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: paid ? Colors.green : Colors.red,
            )),
            const SizedBox(width: 4),
            Checkbox(
              value: paid,
              onChanged: (_) async {
                await repo.togglePaid(expense.id);
                onRefresh();
              },
              activeColor: Colors.green,
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: expense)),
          );
          if (result == true) onRefresh();
        },
      ),
    );
  }
}
