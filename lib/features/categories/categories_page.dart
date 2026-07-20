import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/category_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

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
          final byCategory = <String, List<Expense>>{};
          for (final e in expenses) {
            byCategory.putIfAbsent(e.category, () => []).add(e);
          }

          final allCats = catService.categories;
          final grandTotal = expenses.fold<double>(0, (s, e) => s + e.amount);

          final catEntries = allCats.map((cat) {
            final catExpenses = byCategory[cat.name] ?? [];
            final total = catExpenses.fold<double>(0, (s, e) => s + e.amount);
            return _CatEntry(name: cat.name, icon: cat.icon, color: cat.color, expenses: catExpenses, total: total);
          }).where((e) => e.total > 0 || e.expenses.isNotEmpty).toList();

          final catsWithNoExpenses = allCats.where((cat) {
            final catExpenses = byCategory[cat.name];
            return catExpenses == null || catExpenses.isEmpty;
          }).toList();

          final sorted = [...catEntries..sort((a, b) => b.total.compareTo(a.total)), ...catsWithNoExpenses.map((cat) => _CatEntry(name: cat.name, icon: cat.icon, color: cat.color, expenses: [], total: 0))];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Categorias',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    'Total: ${grandTotal.toStringAsFixed(2)}€',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
              if (sorted.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Sem categorias.')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = sorted[index];
                      final total = entry.total;
                      final percentage = grandTotal > 0 ? (total / grandTotal * 100) : 0.0;
                      final paid = entry.expenses.where((e) => e.isPaid).fold<double>(0, (s, e) => s + e.amount);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: entry.color.withValues(alpha: 0.15),
                            child: Icon(entry.icon, color: entry.color),
                          ),
                          title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            entry.expenses.isEmpty
                                ? 'Sem despesas'
                                : '${total.toStringAsFixed(2)}€ · ${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: entry.expenses.isNotEmpty
                              ? Text('${entry.expenses.length}', style: TextStyle(color: Colors.grey.shade500))
                              : null,
                          children: entry.expenses.isEmpty
                              ? []
                              : [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    child: Column(
                                      children: [
                                        LinearProgressIndicator(
                                          value: grandTotal > 0 ? total / grandTotal : 0,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation(entry.color),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Pago: ${paid.toStringAsFixed(2)}€',
                                                style: const TextStyle(fontSize: 12, color: Colors.green)),
                                            Text('Pendente: ${(total - paid).toStringAsFixed(2)}€',
                                                style: const TextStyle(fontSize: 12, color: Colors.red)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...entry.expenses.map((e) => ListTile(
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(e.name),
                                              subtitle: Text('${e.amount.toStringAsFixed(2)}€ · Dia ${e.dueDay ?? '?'}'),
                                              trailing: Icon(
                                                e.isPaid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                                                color: e.isPaid ? Colors.green : Colors.red,
                                                size: 20,
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CatEntry {
  final String name;
  final IconData icon;
  final Color color;
  final List<Expense> expenses;
  final double total;
  const _CatEntry({required this.name, required this.icon, required this.color, required this.expenses, required this.total});
}
