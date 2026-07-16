// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _CalendarTab(),
          _CategoriesTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendário'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categorias'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Definições'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

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
              if (expenses.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Sem despesas ainda.\nToca em + para adicionar.'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ExpenseTile(expense: expenses[index]),
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
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ExpenseRepository>();
    final paid = expense.isPaid;
    final amountStr = '${expense.amount.toStringAsFixed(2)} €';
    final dueLabel = expense.dueDay != null ? 'Dia ${expense.dueDay}' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: paid ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            paid ? Icons.check : Icons.close,
            color: paid ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(expense.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$dueLabel · ${expense.category}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(amountStr, style: TextStyle(fontWeight: FontWeight.bold, color: paid ? Colors.green : Colors.red)),
            const SizedBox(width: 4),
            Checkbox(
              value: paid,
              onChanged: (_) => repo.togglePaid(expense.id),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Calendário — em breve'));
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Categorias — em breve'));
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Definições — em breve'));
  }
}
