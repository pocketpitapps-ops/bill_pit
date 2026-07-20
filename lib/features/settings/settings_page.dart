import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/category_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import '../home/home_page.dart';
import '../legal/privacy_policy_page.dart';
import '../legal/terms_of_service_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExpenseRepository>();

    return SafeArea(
      child: FutureBuilder<List<Expense>>(
        future: repo.getAll(),
        builder: (context, snapshot) {
          final hasExpenses = snapshot.hasData && snapshot.data!.isNotEmpty;

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
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notificações'),
                      subtitle: const Text('Resumos, semanais e atrasadas'),
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
                      subtitle: const Text('Seguir sistema'),
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
                    if (hasExpenses) ...[
                      ListTile(
                        leading: const Icon(Icons.delete_sweep_outlined),
                        title: const Text('Limpar dados de exemplo'),
                        subtitle: const Text('Remover todas as despesas seed'),
                        onTap: () => _confirmClearSeed(context),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                    ],
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Repor dados iniciais'),
                      subtitle: const Text('Repor despesas e categorias de fábrica'),
                      onTap: () => _confirmReset(context),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Sobre o Bill Pit'),
                      subtitle: const Text('v0.1.0'),
                      onTap: () => _showAbout(context),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Política de Privacidade'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Termos de Utilização'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
    ThemeMode selected = ThemeMode.system;
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

  void _confirmClearSeed(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar dados?'),
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
        title: const Text('Repor dados iniciais?'),
        content: const Text('Isto irá eliminar todos os dados atuais e repor as despesas e categorias de fábrica.'),
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
              await repo.seedIfEmpty();
              await catService.reset();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dados repostos.')),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (_) => false,
                );
              }
            },
            child: const Text('Repor', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Bill Pit',
      applicationVersion: '0.1.0',
      applicationIcon: Icon(
        Icons.receipt_long,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: const [
        Text('Controlo de despesas mensais.\nDesenvolvido com Flutter.'),
      ],
    );
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final day = await NotificationService.getMonthlySummaryDay();
    setState(() => _summaryDay = day);
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Notificações', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _NotificationTile(
            icon: Icons.calendar_month_outlined,
            title: 'Resumo Mensal',
            subtitle: 'Dia $_summaryDay de cada mês',
            onTap: () => _pickSummaryDay(context),
          ),
          _NotificationTile(
            icon: Icons.view_week_outlined,
            title: 'Preview Semanal',
            subtitle: 'Domingo às 21h — próximos pagamentos',
            enabled: false,
          ),
          _NotificationTile(
            icon: Icons.warning_amber_outlined,
            title: 'Atrasadas',
            subtitle: 'Diariamente às 9h — despesas não pagas',
            enabled: false,
          ),
          _NotificationTile(
            icon: Icons.edit_calendar_outlined,
            title: 'Valores por retificar',
            subtitle: 'Verifica se despesas variáveis foram atualizadas',
            enabled: false,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickSummaryDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year, DateTime.now().month, _summaryDay),
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDate: DateTime(DateTime.now().year, DateTime.now().month, 28),
    );
    if (picked != null) {
      setState(() => _summaryDay = picked.day);
      await NotificationService.setMonthlySummaryDay(_summaryDay);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(title, style: enabled ? null : const TextStyle(color: Colors.grey)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: enabled ? Colors.grey.shade600 : Colors.grey.shade400)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: enabled ? onTap : null,
      contentPadding: EdgeInsets.zero,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ...catService.categories.map((cat) => _CategoryTile(cat: cat)),
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
  const _CategoryTile({required this.cat});

  @override
  Widget build(BuildContext context) {
    final catService = context.read<CategoryService>();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cat.color.withValues(alpha: 0.15),
        child: Icon(cat.icon, color: cat.color, size: 20),
      ),
      title: Text(cat.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () => _confirmDelete(context, catService),
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

    if (_isEditing) {
      await catService.update(
        oldName!,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
      );
      if (oldName != name && context.mounted) {
        final repo = context.read<ExpenseRepository>();
        final moved = await repo.renameCategory(oldName, name);
        if (context.mounted && moved > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$moved despesa(s) atualizada(s) para "$name".')),
          );
        }
      }
    } else {
      await catService.add(name, _selectedIcon, _selectedColor);
    }

    if (context.mounted) Navigator.pop(context);
  }
}
