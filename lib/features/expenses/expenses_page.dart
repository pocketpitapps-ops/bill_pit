import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/category_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../expense_form/expense_form_page.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String? _selectedCategory;
  Key _key = UniqueKey();

  void _refresh() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExpenseRepository>();
    final catService = context.watch<CategoryService>();

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Expense>>(
          key: _key,
          future: repo.getAll(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allExpenses = snapshot.data!;
            final expenses = _selectedCategory != null
                ? allExpenses.where((e) => e.category == _selectedCategory).toList()
                : allExpenses;

            final total = expenses.fold<double>(0, (s, e) => s + e.amount);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Despesas',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)}€',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: const Text('Todas'),
                            selected: _selectedCategory == null,
                            onSelected: (_) => setState(() => _selectedCategory = null),
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          ),
                        ),
                        ...catService.categories.map((cat) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                avatar: Icon(cat.icon, size: 16, color: cat.color),
                                label: Text(cat.name),
                                selected: _selectedCategory == cat.name,
                                onSelected: (_) => setState(() {
                                  _selectedCategory = _selectedCategory == cat.name ? null : cat.name;
                                }),
                                selectedColor: cat.color.withValues(alpha: 0.15),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                if (expenses.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('Sem despesas nesta categoria.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ExpenseTile(
                          expense: expenses[index],
                          onRefresh: _refresh,
                        ),
                        childCount: expenses.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
          );
          if (result == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onRefresh;
  const _ExpenseTile({required this.expense, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ExpenseRepository>();
    final catService = context.read<CategoryService>();
    final paid = expense.isPaid;
    final amountStr = '${expense.amount.toStringAsFixed(2)}€';
    final dueLabel = expense.dueDay != null ? 'Dia ${expense.dueDay}' : '';

    final catData = catService.findByName(expense.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (catData?.color ?? Colors.grey).withValues(alpha: 0.15),
          child: Icon(catData?.icon ?? Icons.more_horiz, color: catData?.color ?? Colors.grey, size: 20),
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
