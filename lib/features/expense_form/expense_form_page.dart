import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/category_service.dart';
import '../../core/services/value_tracking_service.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';

enum _VisibleType { fixed, periodic, unique }

class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;
  final int? initialDueDay;
  const ExpenseFormPage({super.key, this.expense, this.initialDueDay});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dueDayCtrl;
  late TextEditingController _installmentsCtrl;
  late _VisibleType _visibleType;
  late bool _isVariable;
  late String _category;
  late bool _isPaid;
  late int _frequency;

  DateTime? _startDate;
  DateTime? _endDate;

  static const _frequencyOptions = <int>[1, 2, 3, 6, 12];
  static const _frequencyLabels = {
    1: 'Mensal',
    2: 'Bimestral',
    3: 'Trimestral',
    6: 'Semestral',
    12: 'Anual',
  };

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toStringAsFixed(2) : '');
    _dueDayCtrl = TextEditingController(text: e?.dueDay?.toString() ?? '');
    _installmentsCtrl = TextEditingController(text: e?.installments?.toString() ?? '');
    _category = e?.category ?? '';
    _isPaid = e?.isPaid ?? false;
    _startDate = e?.startDate;
    _endDate = e?.endDate;

    if (e != null) {
      _visibleType = _expenseTypeToVisible(e.type);
      if (e.type == ExpenseType.periodic) {
        final raw = e.notifyDaysBefore;
        _frequency = raw.abs() > 0 ? raw.abs() : 1;
        _isVariable = raw < 0;
      } else {
        _isVariable = e.type == ExpenseType.monthly;
        _frequency = 1;
      }
    } else {
      _visibleType = _VisibleType.fixed;
      _isVariable = false;
      _frequency = 1;
      if (widget.initialDueDay != null) {
        _dueDayCtrl.text = widget.initialDueDay.toString();
      }
    }
  }

  _VisibleType _expenseTypeToVisible(ExpenseType t) {
    switch (t) {
      case ExpenseType.fixed:
      case ExpenseType.monthly:
        return _VisibleType.fixed;
      case ExpenseType.periodic:
        return _VisibleType.periodic;
      case ExpenseType.unique:
        return _VisibleType.unique;
    }
  }

  ExpenseType get _internalType {
    switch (_visibleType) {
      case _VisibleType.fixed:
        return _isVariable ? ExpenseType.monthly : ExpenseType.fixed;
      case _VisibleType.periodic:
        return ExpenseType.periodic;
      case _VisibleType.unique:
        return ExpenseType.unique;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _dueDayCtrl.dispose();
    _installmentsCtrl.dispose();
    super.dispose();
  }

  bool get _showDueDay => _visibleType == _VisibleType.fixed;
  bool get _showPeriodicFields => _visibleType == _VisibleType.periodic;
  bool get _showUniqueDate => _visibleType == _VisibleType.unique;
  bool get _showVariableToggle => _showDueDay || _showPeriodicFields;
  bool get _showInstallments => _showPeriodicFields && !_isVariable && _frequency == 1;

  String get _typeDescription {
    switch (_visibleType) {
      case _VisibleType.fixed:
        return _isVariable
            ? 'Recorrente mensal. Valor muda a cada mês. Ex: luz, água.'
            : 'Valor fixo todos os meses. Ex: renda, seguro.';
      case _VisibleType.periodic:
        return _isVariable
            ? 'Recorrente. Prestação pode variar. Ex: crédito francês.'
            : 'Recorrente com prestação fixa. Ex: crédito pessoal.';
      case _VisibleType.unique:
        return 'Uma única vez. Sem repetição. Ex: avaria.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final catService = context.watch<CategoryService>();
    final allCategories = catService.categories;
    final defaultCatName = allCategories.isNotEmpty ? allCategories.first.name : '';

    if (!_isEditing) {
      _category = defaultCatName;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Despesa' : 'Nova Despesa'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CategoryDropdown(
              categories: allCategories,
              selected: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<_VisibleType>(
              initialValue: _visibleType,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: _VisibleType.fixed, child: Text('Fixa')),
                DropdownMenuItem(value: _VisibleType.periodic, child: Text('Periódica')),
                DropdownMenuItem(value: _VisibleType.unique, child: Text('Única')),
              ],
              onChanged: (v) => setState(() {
                _visibleType = v!;
                if (v != _VisibleType.fixed) _isVariable = false;
              }),
            ),
            if (_showVariableToggle) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Valor fixo'),
                      selected: !_isVariable,
                      onSelected: (_) => setState(() => _isVariable = false),
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Valor variável'),
                      selected: _isVariable,
                      onSelected: (_) => setState(() => _isVariable = true),
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _typeDescription,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            if (_isVariable && _showVariableToggle) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Atualiza o valor quando receberes a factura.',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_showDueDay) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDayCtrl,
                decoration: const InputDecoration(labelText: 'Dia do mês', hintText: '1-31'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 1 || n > 31) return 'Inválido (1-31)';
                  return null;
                },
              ),
            ],
            if (_showPeriodicFields) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequência'),
                items: _frequencyOptions
                    .map((f) => DropdownMenuItem(value: f, child: Text(_frequencyLabels[f]!)))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data início'),
                subtitle: Text(
                  _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Selecionar data',
                  style: TextStyle(
                    color: _startDate != null ? null : Theme.of(context).colorScheme.primary,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),
              if (_showInstallments) ...[
                TextFormField(
                  controller: _installmentsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prestações',
                    hintText: 'Ex: 12',
                    suffixText: 'prestações',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null || n < 1) return 'Mínimo 1';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Número de prestações. Se não preencher, recorre para sempre.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Text('Data fim'),
                      const SizedBox(width: 8),
                      Text('(opcional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  subtitle: Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Sem data fim — recorrente para sempre',
                    style: TextStyle(
                      color: _endDate != null ? null : Colors.grey.shade500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _endDate = null),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _startDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                ),
              ],
              if (_startDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _showInstallments
                      ? _PeriodicPreview(
                          amount: double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0,
                          startDate: _startDate!,
                          installments: int.tryParse(_installmentsCtrl.text),
                          frequency: _frequency,
                        )
                      : _PeriodicPreview(
                          amount: double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0,
                          startDate: _startDate!,
                          endDate: _endDate,
                          frequency: _frequency,
                        ),
                ),
            ],
            if (_showUniqueDate) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(
                  _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Selecionar data',
                  style: TextStyle(
                    color: _startDate != null ? null : Theme.of(context).colorScheme.primary,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome', hintText: 'Ex: Renda'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Valor (€)', hintText: '0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_isEditing)
              SwitchListTile(
                title: const Text('Pago'),
                value: _isPaid,
                onChanged: (v) => setState(() => _isPaid = v),
                activeThumbColor: Theme.of(context).colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Guardar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_showPeriodicFields && _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona a data início.')),
      );
      return;
    }
    if (_showUniqueDate && _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona a data da despesa.')),
      );
      return;
    }

    final repo = context.read<ExpenseRepository>();
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    final dueDay = int.tryParse(_dueDayCtrl.text);
    final installments = int.tryParse(_installmentsCtrl.text);
    final freqValue = _showPeriodicFields
        ? (_isVariable ? -_frequency : _frequency)
        : (_isVariable ? 1 : 0);

    final useInstallments = _showInstallments;
    final useEndDate = _showPeriodicFields && !useInstallments;

    int savedId;
    if (_isEditing) {
      final e = widget.expense!
        ..name = _nameCtrl.text.trim()
        ..amount = amount
        ..type = _internalType
        ..category = _category
        ..dueDay = _showDueDay ? dueDay : null
        ..startDate = _startDate
        ..endDate = useEndDate ? _endDate : null
        ..installments = useInstallments ? installments : null
        ..notifyDaysBefore = freqValue
        ..isPaid = _isPaid;
      await repo.update(e);
      savedId = e.id;
    } else {
      final e = Expense()
        ..name = _nameCtrl.text.trim()
        ..amount = amount
        ..type = _internalType
        ..category = _category
        ..dueDay = _showDueDay ? dueDay : null
        ..startDate = _startDate
        ..endDate = useEndDate ? _endDate : null
        ..installments = useInstallments ? installments : null
        ..notifyDaysBefore = freqValue
        ..isPaid = false
        ..isActive = true;
      savedId = await repo.create(e);
    }
    if (_isVariable) {
      await ValueTrackingService.recordUpdate(savedId, amount);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar despesa?'),
        content: Text('Eliminar "${widget.expense!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ExpenseRepository>().delete(widget.expense!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }
}

// ── Category Dropdown with "+" button ──

class _CategoryDropdown extends StatelessWidget {
  final List<AppCategory> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: const InputDecoration(labelText: 'Categoria'),
      items: [
        ...categories.map((cat) => DropdownMenuItem(
              value: cat.name,
              child: Row(
                children: [
                  Icon(cat.icon, size: 18, color: cat.color),
                  const SizedBox(width: 8),
                  Text(cat.name),
                ],
              ),
            )),
        DropdownMenuItem(
          value: '__add_new__',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Nova categoria', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      onChanged: (v) {
        if (v == '__add_new__') {
          _showAddCategory(context);
        } else if (v != null) {
          onChanged(v);
        }
      },
    );
  }

  void _showAddCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _InlineCategoryForm(
        categoryService: context.read<CategoryService>(),
        onCreated: (name) {
          onChanged(name);
        },
      ),
    );
  }
}

class _InlineCategoryForm extends StatefulWidget {
  final CategoryService categoryService;
  final ValueChanged<String> onCreated;
  const _InlineCategoryForm({required this.categoryService, required this.onCreated});

  @override
  State<_InlineCategoryForm> createState() => _InlineCategoryFormState();
}

class _InlineCategoryFormState extends State<_InlineCategoryForm> {
  final _nameCtrl = TextEditingController();
  IconData _selectedIcon = Icons.category_outlined;
  Color _selectedColor = const Color(0xFF6366F1);

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
    final used = widget.categoryService.usedIconCodePoints;
    return _allIcons.where((i) => !used.contains(i.codePoint)).toList();
  }

  List<Color> get _availableColors {
    final used = widget.categoryService.usedColorValues;
    return _allColors.where((c) => !used.contains(c.toARGB32())).toList();
  }

  @override
  void initState() {
    super.initState();
    if (_availableIcons.isNotEmpty) _selectedIcon = _availableIcons.first;
    if (_availableColors.isNotEmpty) _selectedColor = _availableColors.first;
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
          Text('Nova Categoria', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
              onPressed: () {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome é obrigatório.')),
                  );
                  return;
                }
                if (widget.categoryService.nameExists(name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Já existe uma categoria com esse nome.')),
                  );
                  return;
                }
                context.read<CategoryService>().add(name, _selectedIcon, _selectedColor);
                Navigator.pop(context);
                widget.onCreated(name);
              },
              child: const Text('Adicionar'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PeriodicPreview extends StatelessWidget {
  final double amount;
  final DateTime startDate;
  final int? installments;
  final DateTime? endDate;
  final int frequency;

  static const _frequencyLabels = {
    1: 'Mensal',
    2: 'Bimestral',
    3: 'Trimestral',
    6: 'Semestral',
    12: 'Anual',
  };

  const _PeriodicPreview({
    required this.amount,
    required this.startDate,
    this.installments,
    this.endDate,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final freqLabel = _frequencyLabels[frequency] ?? 'A cada $frequency meses';

    if (installments != null && installments! > 0) {
      final total = amount * installments!;
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.calculate_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$installments × ${amount.toStringAsFixed(2)}€ ($freqLabel)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Total: ${total.toStringAsFixed(2)}€',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (endDate != null) {
      final totalMonths = (endDate!.year - startDate.year) * 12 + (endDate!.month - startDate.month) + 1;
      final intervals = (totalMonths / frequency).ceil();
      if (intervals <= 0) return const SizedBox();
      final total = amount * intervals;
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.calculate_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$intervals × ${amount.toStringAsFixed(2)}€ ($freqLabel)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Total: ${total.toStringAsFixed(2)}€',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final annualAmount = amount * (12 / frequency);
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.repeat, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${amount.toStringAsFixed(2)}€ — $freqLabel',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '≈ ${annualAmount.toStringAsFixed(2)}€/ano',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
}
