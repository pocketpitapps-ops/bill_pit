import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/constants/categories.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

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
          final byCategory = <String, List<Expense>>{};
          for (final e in expenses) {
            byCategory.putIfAbsent(e.category, () => []).add(e);
          }

          final sorted = byCategory.entries.toList()
            ..sort((a, b) {
              final totalA = a.value.fold<double>(0, (s, e) => s + e.amount);
              final totalB = b.value.fold<double>(0, (s, e) => s + e.amount);
              return totalB.compareTo(totalA);
            });

          final grandTotal = expenses.fold<double>(0, (s, e) => s + e.amount);

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
                  child: Center(child: Text('Sem despesas.')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = sorted[index];
                      final catData = categories.values.firstWhere(
                        (c) => c.name == entry.key,
                        orElse: () => const CategoryData('Outro', Icons.more_horiz, Colors.grey),
                      );
                      final total = entry.value.fold<double>(0, (s, e) => s + e.amount);
                      final paid = entry.value.where((e) => e.isPaid).fold<double>(0, (s, e) => s + e.amount);
                      final percentage = grandTotal > 0 ? (total / grandTotal * 100) : 0.0;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: catData.color.withValues(alpha: 0.15),
                            child: Icon(catData.icon, color: catData.color),
                          ),
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${total.toStringAsFixed(2)}€ · ${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Text(
                            '${entry.value.length}',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: grandTotal > 0 ? total / grandTotal : 0,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(catData.color),
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
                                  ...entry.value.map((e) => ListTile(
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
