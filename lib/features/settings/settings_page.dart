import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/category_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/theme_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../home/home_page.dart';
import '../legal/privacy_policy_page.dart';
import '../legal/terms_of_service_page.dart';
import '../onboarding/onboarding_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _themeLabels = {
    'system': 'Seguir sistema',
    'light': 'Claro',
    'dark': 'Escuro',
  };

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExpenseRepository>();
    final themeService = context.watch<ThemeService>();

    return SafeArea(
      child: FutureBuilder<List<Expense>>(
        future: repo.getAll(),
        builder: (context, snapshot) {
          final hasExpenses = snapshot.hasData && snapshot.data!.isNotEmpty;
          final themeLabel = _themeLabels[themeService.themeMode.name] ?? 'Sistema';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Definições',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Ver tutorial'),
                      subtitle: const Text('Rever a introdução da app'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _replayTutorial(context),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notificações'),
                      subtitle: const Text('Resumo mensal, semanal e lembretes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showNotificationSettings(context),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Categorias'),
                      subtitle: const Text('Adicionar, editar ou remover'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showCategoriesManager(context),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Tema'),
                      subtitle: Text(themeLabel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showThemeDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Política de Privacidade'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Termos de Utilização'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Guardar backup'),
                      subtitle: const Text('Exportar para Documents/BillPit/'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportBackup(context),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Restaurar backup'),
                      subtitle: const Text('Importar de Documents/BillPit/'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _importBackup(context),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: const Text('Partilhar backup'),
                      subtitle: const Text('Enviar ficheiro JSON por apps'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _shareBackup(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (hasExpenses)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmClearAll(context),
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    label: const Text('Limpar todos os dados', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  ),
                ),
              if (hasExpenses) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context),
                  icon: const Icon(Icons.restore_outlined, color: Colors.orange),
                  label: const Text('Recomeçar app do zero', style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _replayTutorial(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingPage(fromSettings: true)),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _NotificationSettingsSheet(),
    );
  }

  void _showCategoriesManager(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _CategoriesManagerPage()));
  }

  void _showThemeDialog(BuildContext context) {
    final themeService = context.read<ThemeService>();
    ThemeMode selected = themeService.themeMode;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tema'),
          content: RadioGroup<ThemeMode>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selected = value);
                themeService.setTheme(value);
                Navigator.pop(ctx);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(title: Text('Sistema'), value: ThemeMode.system),
                RadioListTile<ThemeMode>(title: Text('Claro'), value: ThemeMode.light),
                RadioListTile<ThemeMode>(title: Text('Escuro'), value: ThemeMode.dark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar todos os dados?'),
        content: const Text('Isto irá eliminar todas as despesas. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final repo = context.read<ExpenseRepository>();
              final all = await repo.getAll();
              for (final e in all) {
                await repo.delete(e.id);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dados eliminados.')),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (_) => false,
                );
              }
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recomeçar do zero?'),
        content: const Text('Isto irá eliminar todos os dados (despesas e categorias personalizadas). A app ficará como se fosse a primeira vez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final repo = context.read<ExpenseRepository>();
              final catService = context.read<CategoryService>();
              final all = await repo.getAll();
              for (final e in all) {
                await repo.delete(e.id);
              }
              await catService.reset();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App reiniciada.')),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (_) => false,
                );
              }
            },
            child: const Text('Recomeçar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final repo = context.read<ExpenseRepository>();
      final catService = context.read<CategoryService>();
      await BackupService.autoBackup(repo: repo, catService: catService);
      final date = await BackupService.lastAutoBackupDate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup guardado em Documents/BillPit/${date != null ? _fmt(date) : ""}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _shareBackup(BuildContext context) async {
    try {
      final repo = context.read<ExpenseRepository>();
      final catService = context.read<CategoryService>();
      await BackupService.exportAndShare(repo: repo, catService: catService);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup partilhado com sucesso.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao partilhar: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final hasBackup = await BackupService.hasAutoBackup();
      if (!hasBackup) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum backup encontrado em Documents/BillPit/.')),
          );
        }
        return;
      }

      final data = await BackupService.importFromAutoBackup();
      if (data == null) return;

      final expensesCount = (data['expenses'] as List?)?.length ?? 0;
      final categoriesCount = (data['categories'] as List?)?.length ?? 0;
      final exportedAt = data['exportedAt'] as String?;

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restaurar backup?'),
          content: Text(
            'Backup de${exportedAt != null ? ' ${exportedAt.substring(0, 10)}' : ''}:\n'
            '• $expensesCount despesa(s)\n'
            '• $categoriesCount categoria(s)\n\n'
            'Substituir todos os dados atuais?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );

      if (confirm != true || !context.mounted) return;

      final repo = context.read<ExpenseRepository>();
      final catService = context.read<CategoryService>();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A restaurar dados...')),
      );

      await BackupService.restore(
        data: data,
        repo: repo,
        catService: catService,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          'Restaurado: $expensesCount despesas, $categoriesCount categorias.'
        )),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar: $e')),
        );
      }
    }
  }
}

// ── Notification Settings ──

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  int _summaryDay = 28;
  int _summaryHour = 9;
  int _weeklyHour = 21;
  int _overdueDays = 3;
  int _overdueHour = 9;
  int _defaultReminderDays = 3;
  late TextEditingController _reminderDaysCtrl;

  @override
  void initState() {
    super.initState();
    _reminderDaysCtrl = TextEditingController(text: '$_defaultReminderDays');
    _loadSettings();
  }

  @override
  void dispose() {
    _reminderDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final day = await NotificationService.getMonthlySummaryDay();
    final sHour = await NotificationService.getMonthlySummaryHour();
    final wHour = await NotificationService.getWeeklyPreviewHour();
    final oDays = await NotificationService.getOverdueDays();
    final oHour = await NotificationService.getOverdueHour();
    final dDays = await NotificationService.getDefaultReminderDays();
    setState(() {
      _summaryDay = day;
      _summaryHour = sHour;
      _weeklyHour = wHour;
      _overdueDays = oDays;
      _overdueHour = oHour;
      _defaultReminderDays = dDays;
      _reminderDaysCtrl.text = '$dDays';
    });
  }

  void _saveReminderDays() {
    final value = int.tryParse(_reminderDaysCtrl.text);
    if (value == null || value < 1 || value > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insere um valor entre 1 e 15.')),
      );
      _reminderDaysCtrl.text = '$_defaultReminderDays';
      return;
    }
    setState(() => _defaultReminderDays = value);
    NotificationService.setDefaultReminderDays(value);
  }

  String _hourLabel(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Notificações', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _NotificationTile(
              icon: Icons.calendar_month_outlined,
              title: 'Resumo Mensal',
              subtitle: 'Dia $_summaryDay de cada mês às ${_hourLabel(_summaryHour)}',
              onTap: () => _pickSummaryDateTime(),
            ),
            _NotificationTile(
              icon: Icons.view_week_outlined,
              title: 'Preview Semanal',
              subtitle: 'Domingo às ${_hourLabel(_weeklyHour)}',
              onTap: () => _pickWeeklyHour(),
            ),
            _NotificationTile(
              icon: Icons.warning_amber_outlined,
              title: 'Despesas atrasadas',
              subtitle: 'Lembrete $_overdueDays dia(s) após o vencimento, às ${_hourLabel(_overdueHour)}',
              onTap: () => _pickOverdueSettings(),
            ),
            const Divider(height: 32),
            Text('Lembrete padrão', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Valor padrão para novas despesas (1-15 dias antes)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.notifications_outlined, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _reminderDaysCtrl,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      hintText: '3',
                      suffixText: 'dia(s) antes',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (_) => _saveReminderDays(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSummaryDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year, DateTime.now().month, _summaryDay),
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDate: DateTime(DateTime.now().year, DateTime.now().month, 28),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _summaryHour, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _summaryDay = date.day;
      _summaryHour = time.hour;
    });
    await NotificationService.setMonthlySummaryDay(_summaryDay);
    await NotificationService.setMonthlySummaryHour(_summaryHour);
  }

  Future<void> _pickWeeklyHour() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _weeklyHour, minute: 0),
    );
    if (time != null && mounted) {
      setState(() => _weeklyHour = time.hour);
      await NotificationService.setWeeklyPreviewHour(_weeklyHour);
    }
  }

  Future<void> _pickOverdueSettings() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _overdueHour, minute: 0),
    );
    if (time == null || !mounted) return;

    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => _OverdueDaysPicker(initialDays: _overdueDays),
    );

    if (!mounted) return;
    setState(() {
      _overdueHour = time.hour;
      if (days != null) _overdueDays = days;
    });
    await NotificationService.setOverdueHour(_overdueHour);
    await NotificationService.setOverdueDays(_overdueDays);
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _OverdueDaysPicker extends StatefulWidget {
  final int initialDays;
  const _OverdueDaysPicker({required this.initialDays});

  @override
  State<_OverdueDaysPicker> createState() => _OverdueDaysPickerState();
}

class _OverdueDaysPickerState extends State<_OverdueDaysPicker> {
  late int _days;

  @override
  void initState() {
    super.initState();
    _days = widget.initialDays;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Janela de lembretes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Notificar durante $_days dia(s) após o vencimento'),
          Slider(
            value: _days.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_days dia(s)',
            onChanged: (v) => setState(() => _days = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _days), child: const Text('Guardar')),
      ],
    );
  }
}

// ── Categories Manager Page ──

class _CategoriesManagerPage extends StatelessWidget {
  const _CategoriesManagerPage();

  @override
  Widget build(BuildContext context) {
    final catService = context.watch<CategoryService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: ReorderableListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        onReorderItem: (data, newIndex) {
          final name = data as String;
          final oldIndex = catService.categories.indexWhere((c) => c.name == name);
          if (oldIndex != -1) catService.reorder(oldIndex, newIndex);
          FocusScope.of(context).unfocus();
        },
        children: [
          for (final cat in catService.categories)
            _CategoryTile(key: ValueKey(cat.name), cat: cat),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {AppCategory? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CategoryFormSheet(existing: existing),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final AppCategory cat;
  const _CategoryTile({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    final catService = context.read<CategoryService>();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cat.color.withValues(alpha: 0.15),
        child: Icon(cat.icon, color: cat.color, size: 20),
      ),
      title: Text(cat.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _confirmDelete(context, catService),
          ),
          const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
        ],
      ),
      onTap: () => _showEditSheet(context),
    );
  }

  void _confirmDelete(BuildContext context, CategoryService catService) async {
    final repo = context.read<ExpenseRepository>();
    final count = await repo.countByCategory(cat.name);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoria?'),
        content: Text(
          count > 0
              ? 'Eliminar "${cat.name}"?\n\n$count despesa(s) serão movidas para "Outros".'
              : 'Eliminar "${cat.name}"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (count > 0) {
                await repo.moveCategory(cat.name, 'Outros');
              }
              final deleted = await catService.delete(cat.name);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      deleted
                          ? count > 0
                              ? '${cat.name} eliminada. $count despesa(s) movida(s) para Outros.'
                              : '${cat.name} eliminada.'
                          : 'Não foi possível eliminar.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CategoryFormSheet(existing: cat),
    );
  }
}

// ── Category Form Sheet ──

class _CategoryFormSheet extends StatefulWidget {
  final AppCategory? existing;
  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late TextEditingController _nameCtrl;
  late IconData _selectedIcon;
  late Color _selectedColor;
  bool get _isEditing => widget.existing != null;

  static const _allIcons = <IconData>[
    Icons.home_outlined,
    Icons.directions_car_outlined,
    Icons.bolt_outlined,
    Icons.water_outlined,
    Icons.local_fire_department_outlined,
    Icons.subscriptions_outlined,
    Icons.credit_card_outlined,
    Icons.favorite_outline,
    Icons.school_outlined,
    Icons.restaurant_outlined,
    Icons.sports_esports_outlined,
    Icons.shopping_bag_outlined,
    Icons.pets_outlined,
    Icons.flight_outlined,
    Icons.phone_outlined,
    Icons.wifi_outlined,
    Icons.local_laundry_service_outlined,
    Icons.build_outlined,
    Icons.local_cafe_outlined,
    Icons.movie_outlined,
    Icons.music_note_outlined,
    Icons.fitness_center_outlined,
    Icons.local_grocery_store_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.card_giftcard_outlined,
    Icons.work_outline,
    Icons.child_care_outlined,
    Icons.park_outlined,
    Icons.train_outlined,
    Icons.bus_alert_outlined,
    Icons.pedal_bike_outlined,
    Icons.local_hospital_outlined,
    Icons.cake_outlined,
    Icons.camera_alt_outlined,
    Icons.inventory_2_outlined,
    Icons.savings_outlined,
    Icons.account_balance_outlined,
    Icons.more_horiz,
  ];

  static const _allColors = <Color>[
    Color(0xFF3B82F6), Color(0xFF06B6D4), Color(0xFFF59E0B),
    Color(0xFFF97316), Color(0xFFEF4444), Color(0xFF10B981),
    Color(0xFF14B8A6), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFF6366F1), Color(0xFF64748B), Color(0xFF84CC16),
    Color(0xFFE11D48), Color(0xFF0EA5E9), Color(0xFFD946EF),
    Color(0xFF78716C),
  ];

  List<IconData> get _availableIcons {
    if (_isEditing) return _allIcons;
    final used = context.read<CategoryService>().usedIconCodePoints;
    return _allIcons.where((i) => !used.contains(i.codePoint)).toList();
  }

  List<Color> get _availableColors {
    if (_isEditing) return _allColors;
    final used = context.read<CategoryService>().usedColorValues;
    return _allColors.where((c) => !used.contains(c.toARGB32())).toList();
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.icon ?? Icons.category_outlined;
    _selectedColor = widget.existing?.color ?? _allColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = _availableIcons;
    final colors = _availableColors;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing ? 'Editar Categoria' : 'Nova Categoria',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome', hintText: 'Ex: Viagens'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          if (icons.isNotEmpty) ...[
            Text('Ícone', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: icons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (_, i) {
                  final icon = icons[i];
                  final selected = icon.codePoint == _selectedIcon.codePoint;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: selected ? _selectedColor.withValues(alpha: 0.2) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: selected ? Border.all(color: _selectedColor, width: 2) : null,
                      ),
                      child: Icon(icon, color: selected ? _selectedColor : Colors.grey, size: 20),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (colors.isNotEmpty) ...[
            Text('Cor', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final color = colors[i];
                  final selected = color.toARGB32() == _selectedColor.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black, width: 3) : null,
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Guardar' : 'Adicionar'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome é obrigatório.')),
      );
      return;
    }

    final catService = context.read<CategoryService>();

    if (!_isEditing && catService.nameExists(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma categoria com esse nome.')),
      );
      return;
    }

    final oldName = widget.existing?.name;
    final repo = context.read<ExpenseRepository>();

    if (_isEditing) {
      await catService.update(
        oldName!,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
      );
      if (oldName != name) {
        final moved = await repo.renameCategory(oldName, name);
        if (mounted && moved > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$moved despesa(s) atualizada(s) para "$name".')),
          );
        }
      }
    } else {
      await catService.add(name, _selectedIcon, _selectedColor);
    }

    if (mounted) Navigator.pop(context);
  }
}
