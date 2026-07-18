import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/expense_repository.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
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
                  subtitle: const Text('Gerir lembretes de despesas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNotificationSettings(context),
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
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Limpar dados de exemplo'),
                  subtitle: const Text('Remover todas as despesas seed'),
                  onTap: () => _confirmClearSeed(context),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre o Bill Pit'),
                  subtitle: const Text('v0.1.0'),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativar notificações'),
              subtitle: const Text('Receber lembretes antes do vencimento'),
              value: true,
              onChanged: (v) {},
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Dias antes do vencimento'),
              subtitle: const Text('Predefinido: 3 dias'),
              contentPadding: EdgeInsets.zero,
              onTap: () {},
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
                RadioListTile<ThemeMode>(
                  title: Text('Sistema'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Claro'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Escuro'),
                  value: ThemeMode.dark,
                ),
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
              }
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
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
