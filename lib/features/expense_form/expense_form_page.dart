import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormPage({super.key, this.expense});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dueDayCtrl;
  late TextEditingController _notifyDaysCtrl;
  late ExpenseType _type;
  late String _category;
  late bool _isPaid;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toStringAsFixed(2) : '');
    _dueDayCtrl = TextEditingController(text: e?.dueDay?.toString() ?? '');
    _notifyDaysCtrl = TextEditingController(text: e?.notifyDaysBefore.toString() ?? '3');
    _type = e?.type ?? ExpenseType.monthly;
    _category = e?.category ?? categories.keys.first.name;
    _isPaid = e?.isPaid ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _dueDayCtrl.dispose();
    _notifyDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpenseType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: ExpenseType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(expenseTypeLabels[t]!)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: categories.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key.name,
                        child: Row(
                          children: [
                            Icon(e.value.icon, size: 18, color: e.value.color),
                            const SizedBox(width: 8),
                            Text(e.value.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dueDayCtrl,
              decoration: const InputDecoration(
                labelText: 'Dia do mês',
                hintText: '1-31',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 1 || n > 31) return 'Inválido (1-31)';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notifyDaysCtrl,
              decoration: const InputDecoration(
                labelText: 'Notificar dias antes',
                hintText: '3',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                final n = int.tryParse(v);
                if (n == null || n < 0) return 'Inválido';
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
    final repo = context.read<ExpenseRepository>();
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    final dueDay = int.tryParse(_dueDayCtrl.text);
    final notifyDays = int.parse(_notifyDaysCtrl.text);

    if (_isEditing) {
      final e = widget.expense!
        ..name = _nameCtrl.text.trim()
        ..amount = amount
        ..type = _type
        ..category = _category
        ..dueDay = dueDay
        ..notifyDaysBefore = notifyDays
        ..isPaid = _isPaid;
      await repo.update(e);
    } else {
      final e = Expense()
        ..name = _nameCtrl.text.trim()
        ..amount = amount
        ..type = _type
        ..category = _category
        ..dueDay = dueDay
        ..notifyDaysBefore = notifyDays
        ..isPaid = false
        ..isActive = true;
      await repo.create(e);
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
