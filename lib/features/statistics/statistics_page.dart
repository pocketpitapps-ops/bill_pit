import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/category_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/theme/bill_pit_theme.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

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
            return const Center(child: Text('Sem dados para mostrar.'));
          }

          final grandTotal = expenses.fold<double>(0, (s, e) => s + e.amount);
          final paidTotal = expenses.where((e) => e.isPaid).fold<double>(0, (s, e) => s + e.amount);
          final unpaidTotal = grandTotal - paidTotal;

          final byCategory = <String, double>{};
          for (final e in expenses) {
            byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
          }
          final sortedCats = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Estatísticas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 24),
              Text('Por Categoria', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
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
              const SizedBox(height: 24),
              Text('Detalhe por Categoria', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
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
                                Text('${entry.value.toStringAsFixed(2)}€',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 24),
              Text('Pago vs Pendente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
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
            ],
          );
        },
      ),
    );
  }
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
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
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
