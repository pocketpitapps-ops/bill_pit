import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';

const _taskCheckReminders = 'checkReminders';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _taskCheckReminders) {
      await _checkAndNotify();
    }
    return true;
  });
}

Future<void> _checkAndNotify() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ExpenseSchema],
    directory: dir.path,
    name: 'bill_pit',
  );
  final repo = ExpenseRepository(isar);

  final all = await repo.getAll();
  for (final expense in all) {
    if (expense.isPaid || expense.dueDay == null) continue;

    final dueDate = DateTime(today.year, today.month, expense.dueDay!);
    final difference = dueDate.difference(today).inDays;

    if (difference >= 0 && difference <= expense.notifyDaysBefore) {
      await plugin.show(
        expense.id,
        'Lembrete: ${expense.name}',
        'Vence em $difference dia(s) — ${expense.amount.toStringAsFixed(2)}€',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'bill_pit_reminders',
            'Lembretes de Despesas',
            channelDescription: 'Notificações de vencimento de despesas',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }

  await isar.close();
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin, required ExpenseRepository repo})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> scheduleReminder(Expense expense) async {
    if (expense.isPaid || expense.dueDay == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(now.year, now.month, expense.dueDay!);

    if (dueDate.isBefore(today)) return;

    final difference = dueDate.difference(today).inDays;
    if (difference > expense.notifyDaysBefore) return;

    await _plugin.show(
      expense.id,
      'Lembrete: ${expense.name}',
      'Vence em $difference dia(s) — ${expense.amount.toStringAsFixed(2)}€',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_pit_reminders',
          'Lembretes de Despesas',
          channelDescription: 'Notificações de vencimento de despesas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> initWorkmanager() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'bill_pit_check_reminders',
      _taskCheckReminders,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }
}
