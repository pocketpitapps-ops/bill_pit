import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bill_pit_theme.dart';
import '../../data/repositories/expense_repository.dart';
import '../../features/expense_wizard/expense_wizard_page.dart';
import '../../features/home/home_page.dart';
import 'onboarding_config.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;
  static const _totalPages = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _complete(bool keepData) async {
    await OnboardingConfig.markCompleted();
    if (!mounted) return;
    if (!keepData) {
      final repo = context.read<ExpenseRepository>();
      final all = await repo.getAll();
      for (final e in all) {
        await repo.delete(e.id);
      }
      if (!mounted) return;
      final useWizard = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.auto_awesome_outlined, color: BillPitTheme.primaryLight, size: 48),
          title: const Text('Criar despesas?'),
          content: const Text('Queres ajuda para criar as tuas primeiras despesas com um wizard passo a passo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Agora nao'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sim, usar wizard'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (useWizard == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExpenseWizardPage(fromOnboarding: true)),
        );
        return;
      }
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(),
                  _DashboardPage(),
                  _ExpensesPage(),
                  _CalendarPage(),
                  _ChoicePage(onComplete: _complete),
                ],
              ),
            ),
            if (_currentPage < _totalPages - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () => _goToPage(_currentPage - 1),
                        child: const Text('Voltar'),
                      )
                    else
                      const SizedBox(width: 60),
                    const Spacer(),
                    ...List.generate(_totalPages - 1, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? BillPitTheme.primaryLight
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => _goToPage(_currentPage + 1),
                      child: const Text('Seguinte'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome ──

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: BillPitTheme.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 52,
              color: BillPitTheme.primaryLight,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Bem-vindo ao\nBill Pit',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gestao simples e completa das tuas\ndespesas mensais.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Dashboard ──

class _DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IllustrationBox(
            icon: Icons.dashboard_outlined,
            color: BillPitTheme.primaryLight,
          ),
          const SizedBox(height: 32),
          Text(
            'Painel de controlo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ves de relance o total do mes,\no que esta pago e o que falta.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _MiniSummary(label: 'Total', value: '1.590,00E', color: BillPitTheme.primaryLight),
              const SizedBox(width: 8),
              _MiniSummary(label: 'Pago', value: '0,00E', color: BillPitTheme.paid),
              const SizedBox(width: 8),
              _MiniSummary(label: 'Pendente', value: '1.590,00E', color: BillPitTheme.unpaid),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Colors.green),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '0/10 pagas',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniSummary({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Page 3: Expenses ──

class _ExpensesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IllustrationBox(
            icon: Icons.add_circle_outline,
            color: BillPitTheme.secondaryLight,
          ),
          const SizedBox(height: 32),
          Text(
            'Regista despesas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recorrentes (fixas ou variaveis)\nou unicas. Com categorias,\nvalor e dia de vencimento.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  child: const Icon(Icons.home_outlined, color: Color(0xFF22C55E), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Renda', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Casa  \u00B7  Dia 1', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const Text('750,00E', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 4: Calendar ──

class _CalendarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IllustrationBox(
            icon: Icons.calendar_month_outlined,
            color: BillPitTheme.accent,
          ),
          const SizedBox(height: 32),
          Text(
            'Calendario mensal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Vê dia a dia o que vence.\nNotificacoes automaticas\nantes do vencimento.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _MiniCalendar(),
        ],
      ),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    final dueDays = {1, 5, 10, 12, 15, 20};

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            '${now.month}/${now.year}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(((daysInMonth + firstWeekday - 1) / 7).ceil(), (week) {
            return Row(
              children: List.generate(7, (day) {
                final dayNum = week * 7 + day - (firstWeekday - 2);
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 28));
                }
                final isDue = dueDays.contains(dayNum);
                final isToday = dayNum == now.day;
                return Expanded(
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isDue
                            ? BillPitTheme.primaryLight
                            : isToday
                                ? BillPitTheme.primaryLight.withValues(alpha: 0.12)
                                : null,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isDue ? FontWeight.w700 : FontWeight.normal,
                            color: isDue ? Colors.white : isToday ? BillPitTheme.primaryLight : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

// ── Page 5: Choice ──

class _ChoicePage extends StatelessWidget {
  final Function(bool keepData) onComplete;
  const _ChoicePage({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done_outlined,
            size: 56,
            color: BillPitTheme.secondaryLight,
          ),
          const SizedBox(height: 24),
          Text(
            'Tudo pronto!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Preparamos despesas de exemplo\npara pores a app em pratica.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: _seedPreviewRows(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onComplete(true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Manter exemplos'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onComplete(false),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Comecar do zero'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _seedPreviewRows() {
    const seeds = [
      ('Renda', 'Casa', 750.0, Color(0xFF22C55E)),
      ('Credito hab.', 'Credito', 450.0, Color(0xFFEF4444)),
      ('Combustivel', 'Veiculo', 120.0, Color(0xFFFFFFFF)),
      ('Seguro carro', 'Veiculo', 85.0, Color(0xFFFFFFFF)),
      ('Luz', 'Electricidade', 45.0, Color(0xFFF59E0B)),
      ('Internet', 'Subscricoes', 35.0, Color(0xFF8B5CF6)),
      ('Ginasio', 'Saude', 30.0, Color(0xFFEC4899)),
      ('Agua', 'Agua', 30.0, Color(0xFF3B82F6)),
      ('Gas', 'Gas', 25.0, Color(0xFFF97316)),
      ('Telemovel', 'Subscricoes', 20.0, Color(0xFF8B5CF6)),
    ];

    return seeds.map((s) {
      final ($name, $cat, $amount, $color) = s;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: $color.withValues(alpha: 0.15),
              child: Icon(Icons.circle, size: 8, color: $color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text($name, style: const TextStyle(fontSize: 13)),
            ),
            Text(
              '${$amount.toStringAsFixed(0)},00E',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ── Shared widgets ──

class _IllustrationBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IllustrationBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, size: 44, color: color),
    );
  }
}
