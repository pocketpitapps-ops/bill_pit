import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/category_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../expense_form/expense_form_page.dart';
import '../expense_wizard/expense_wizard_page.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String? _selectedCategory;
  late DateTime _selectedMonth;
  Key _key = UniqueKey();

  static const _monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _refresh() => setState(() => _key = UniqueKey());

  void _prevMonth() => setState(() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _key = UniqueKey();
  });

  void _nextMonth() => setState(() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _key = UniqueKey();
  });

  bool get _isMaxFuture {
    final now = DateTime.now();
    final maxMonth = DateTime(now.year, now.month + 6);
    return !_selectedMonth.isBefore(maxMonth);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExpenseRepository>();
    final catService = context.watch<CategoryService>();

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Expense>>(
          key: _key,
          future: repo.getByMonth(_selectedMonth.month, _selectedMonth.year),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allExpenses = snapshot.data!;
            final monthKey = Expense.monthKey(_selectedMonth.month, _selectedMonth.year);
            final skipped = allExpenses.where((e) => e.skippedMonths.contains(monthKey)).toList();
            final nonSkipped = allExpenses.where((e) => !e.skippedMonths.contains(monthKey)).toList();
            final filtered = _selectedCategory != null
                ? nonSkipped.where((e) => e.category == _selectedCategory).toList()
                : nonSkipped;
            final skippedFiltered = _selectedCategory != null
                ? skipped.where((e) => e.category == _selectedCategory).toList()
                : skipped;

            final now = DateTime.now();
            final unpaidFirst = <Expense>[];
            final paidLast = <Expense>[];
            for (final e in filtered) {
              if (e.paidMonths.contains(monthKey)) {
                paidLast.add(e);
              } else {
                unpaidFirst.add(e);
              }
            }
            final sorted = [...unpaidFirst, ...paidLast];
            final unpaidTotal = unpaidFirst.fold<double>(0, (s, e) => s + e.amount);
            final monthTotal = filtered.fold<double>(0, (s, e) => s + e.amount);
            final paidTotal = monthTotal - unpaidTotal;

            final overdueExpenses = unpaidFirst.where((e) {
              final effectiveDay = e.effectiveDueDay(_selectedMonth.month, _selectedMonth.year);
              final dueDate = DateTime(_selectedMonth.year, _selectedMonth.month, effectiveDay);
              return dueDate.isBefore(DateTime(now.year, now.month, now.day));
            }).toList();
            final overdueTotal = overdueExpenses.fold<double>(0, (s, e) => s + e.amount);
            final hasOverdue = overdueExpenses.isNotEmpty;
            final allPaid = unpaidFirst.isEmpty && filtered.isNotEmpty;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Despesas',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (allPaid)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Liquidado',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${paidTotal.toStringAsFixed(2)}€',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${unpaidTotal.toStringAsFixed(2)}€',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Total: ${monthTotal.toStringAsFixed(2)}€',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              if (hasOverdue)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '(${overdueTotal.toStringAsFixed(2)}€ em dívida)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _prevMonth,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _isMaxFuture ? null : _nextMonth,
                          icon: const Icon(Icons.chevron_right),
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
                if (sorted.isEmpty && skippedFiltered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('Sem despesas neste mês.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < sorted.length) {
                            return _ExpenseTile(
                              expense: sorted[index],
                              month: _selectedMonth.month,
                              year: _selectedMonth.year,
                              onRefresh: _refresh,
                              skipped: false,
                            );
                          }
                          final skippedIndex = index - sorted.length;
                          return _ExpenseTile(
                            expense: skippedFiltered[skippedIndex],
                            month: _selectedMonth.month,
                            year: _selectedMonth.year,
                            onRefresh: _refresh,
                            skipped: true,
                          );
                        },
                        childCount: sorted.length + skippedFiltered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Nova despesa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
              title: const Text('Wizard passo a passo'),
              subtitle: const Text('Criar com ajuda, campo a campo'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpenseWizardPage()),
                );
                if (result == true) _refresh();
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.edit_outlined)),
              title: const Text('Formulario completo'),
              subtitle: const Text('Preencher todos os campos de uma vez'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
                );
                if (result == true) _refresh();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final int month;
  final int year;
  final VoidCallback onRefresh;
  final bool skipped;
  const _ExpenseTile({required this.expense, required this.month, required this.year, required this.onRefresh, this.skipped = false});

  bool get _isVariable => expense.isVariable;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ExpenseRepository>();
    final catService = context.read<CategoryService>();
    final paid = expense.isPaidInMonth(month, year);
    final amountStr = '${expense.amount.toStringAsFixed(2)}€';
    final effectiveDay = expense.effectiveDueDay(month, year);
    final dueLabel = 'Dia $effectiveDay';

    final catData = catService.findByName(expense.category);

    final now = DateTime.now();
    final isOverdue = !skipped && !paid && DateTime(year, month, effectiveDay).isBefore(DateTime(now.year, now.month, now.day));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (skipped ? Colors.grey : (catData?.color ?? Colors.grey)).withValues(alpha: skipped ? 0.05 : 0.15),
          child: Icon(
            catData?.icon ?? Icons.more_horiz,
            color: skipped ? Colors.grey : (catData?.color ?? Colors.grey),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: skipped ? TextDecoration.lineThrough : null,
                  color: skipped ? Colors.grey : null,
                ),
              ),
            ),
            if (_isVariable && !paid && !skipped && !expense.amountConfirmed)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.edit_note, size: 18, color: Colors.amber.shade700),
              ),
          ],
        ),
        subtitle: Text(
          skipped
              ? '$amountStr · Ignorado'
              : '$dueLabel · ${expense.category}',
          style: TextStyle(
            color: skipped ? Colors.grey : (isOverdue ? Colors.red.shade400 : null),
            fontSize: 13,
            decoration: skipped ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: skipped
            ? Icon(Icons.remove_circle_outline, color: Colors.grey.shade400, size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(amountStr, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: paid ? Colors.green : (isOverdue ? Colors.red : Colors.amber.shade700),
                  )),
                  const SizedBox(width: 4),
                  Checkbox(
                    value: paid,
                    onChanged: (_) async {
                      await repo.togglePaidMonth(expense.id, month, year);
                      onRefresh();
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
        onTap: skipped ? null : () async {
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
