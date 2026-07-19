import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import 'value_tracking_service.dart';

const _taskMonthlySummary = 'monthlySummary';
const _taskWeeklyPreview = 'weeklyPreview';
const _taskOverdueCheck = 'overdueCheck';
const _taskValueCheck = 'valueCheck';

const _androidChannelSummary = NotificationChannel(
  id: 'bill_pit_summary',
  name: 'Resumos',
  description: 'Resumos mensais e semanais',
);
const _androidChannelOverdue = NotificationChannel(
  id: 'bill_pit_overdue',
  name: 'Atrasadas',
  description: 'Lembretes de despesas por pagar',
);
const _androidChannelValue = NotificationChannel(
  id: 'bill_pit_value',
  name: 'Valores',
  description: 'Lembretes de atualização de valores variáveis',
);

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case _taskMonthlySummary:
        await _sendMonthlySummary();
        break;
      case _taskWeeklyPreview:
        await _sendWeeklyPreview();
        break;
      case _taskOverdueCheck:
        await _sendOverdueReminder();
        break;
      case _taskValueCheck:
        await _sendValueUpdateReminder();
        break;
    }
    return true;
  });
}

Future<FlutterLocalNotificationsPlugin> _initPlugin() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  return plugin;
}

Future<Isar> _openIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open([ExpenseSchema], directory: dir.path, name: 'bill_pit');
}

Future<String?> _getLastNotificationDate(String topic) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_notification_$topic');
}

Future<void> _setLastNotificationDate(String topic, String date) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_notification_$topic', date);
}

Future<bool> _alreadyNotifiedToday(String topic) async {
  final last = await _getLastNotificationDate(topic);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  return last == today;
}

Future<void> _markNotified(String topic) async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  await _setLastNotificationDate(topic, today);
}

Future<void> _sendMonthlySummary() async {
  if (await _alreadyNotifiedToday('monthly_summary')) return;

  final plugin = await _initPlugin();
  final isar = await _openIsar();
  final repo = ExpenseRepository(isar);

  final all = await repo.getAll();
  if (all.isEmpty) {
    await isar.close();
    return;
  }

  final total = all.fold<double>(0, (s, e) => s + e.amount);
  final paid = all.where((e) => e.isPaid).fold<double>(0, (s, e) => s + e.amount);
  final unpaid = total - paid;
  final unpaidCount = all.where((e) => !e.isPaid).length;

  final now = DateTime.now();
  const months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  final title = 'Resumo de ${months[now.month - 1]}';
  final body = 'Total: ${total.toStringAsFixed(2)}€ | '
      'Pago: ${paid.toStringAsFixed(2)}€ | '
      'Pendente: ${unpaid.toStringAsFixed(2)}€'
      '${unpaidCount > 0 ? ' ($unpaidCount por pagar)' : ''}';

  await plugin.show(
    9001,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelSummary.id,
        _androidChannelSummary.name,
        channelDescription: _androidChannelSummary.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );

  await _markNotified('monthly_summary');
  await isar.close();
}

Future<void> _sendWeeklyPreview() async {
  if (await _alreadyNotifiedToday('weekly_preview')) return;

  final plugin = await _initPlugin();
  final isar = await _openIsar();
  final repo = ExpenseRepository(isar);

  final all = await repo.getAll();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final upcoming = all.where((e) {
    if (e.isPaid || e.dueDay == null) return false;
    final dueDate = DateTime(now.year, now.month, e.dueDay!);
    final diff = dueDate.difference(today).inDays;
    return diff >= 0 && diff <= 7;
  }).toList()..sort((a, b) => (a.dueDay ?? 0).compareTo(b.dueDay ?? 0));

  if (upcoming.isEmpty) {
    await isar.close();
    return;
  }

  final total = upcoming.fold<double>(0, (s, e) => s + e.amount);
  final names = upcoming.map((e) => e.name).join(', ');

  await plugin.show(
    9002,
    'Pagamentos desta semana (${upcoming.length})',
    '$names — Total: ${total.toStringAsFixed(2)}€',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelSummary.id,
        _androidChannelSummary.name,
        channelDescription: _androidChannelSummary.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );

  await _markNotified('weekly_preview');
  await isar.close();
}

Future<void> _sendOverdueReminder() async {
  if (await _alreadyNotifiedToday('overdue')) return;

  final plugin = await _initPlugin();
  final isar = await _openIsar();
  final repo = ExpenseRepository(isar);

  final all = await repo.getAll();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final overdue = all.where((e) {
    if (e.isPaid || e.dueDay == null) return false;
    final dueDate = DateTime(now.year, now.month, e.dueDay!);
    return dueDate.isBefore(today);
  }).toList();

  if (overdue.isEmpty) {
    await isar.close();
    return;
  }

  final total = overdue.fold<double>(0, (s, e) => s + e.amount);
  final names = overdue.map((e) => e.name).join(', ');

  await plugin.show(
    9003,
    '${overdue.length} despesa(s) por pagar',
    '$names — Total: ${total.toStringAsFixed(2)}€',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelOverdue.id,
        _androidChannelOverdue.name,
        channelDescription: _androidChannelOverdue.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );

  await _markNotified('overdue');
  await isar.close();
}

Future<void> _sendValueUpdateReminder() async {
  if (await _alreadyNotifiedToday('value_check')) return;

  final plugin = await _initPlugin();
  final isar = await _openIsar();
  final repo = ExpenseRepository(isar);

  final all = await repo.getAll();
  final variableExpenses = all.where((e) =>
      (e.type == ExpenseType.monthly || (e.type == ExpenseType.periodic && e.notifyDaysBefore < 0)) &&
      !e.isPaid).toList();

  if (variableExpenses.isEmpty) {
    await isar.close();
    return;
  }

  final needsUpdate = <Expense>[];
  for (final e in variableExpenses) {
    final needs = await ValueTrackingService.needsUpdateThisMonth(e.id);
    if (needs) needsUpdate.add(e);
  }

  if (needsUpdate.isEmpty) {
    await isar.close();
    return;
  }

  final names = needsUpdate.map((e) => e.name).join(', ');
  String body = '${needsUpdate.length} despesa(s) variável(is) por atualizar: $names.';

  final first = needsUpdate.first;
  final avg = await ValueTrackingService.getAverage(first.id);
  if (avg != null) {
    body += ' Média ${first.name}: ${avg.toStringAsFixed(2)}€.';
  }

  await plugin.show(
    9004,
    'Valores por retificar',
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelValue.id,
        _androidChannelValue.name,
        channelDescription: _androidChannelValue.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );

  await _markNotified('value_check');
  await isar.close();
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin, required dynamic repo})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> initWorkmanager() async {
    await Workmanager().initialize(callbackDispatcher);

    final prefs = await SharedPreferences.getInstance();
    final summaryDay = prefs.getInt('monthly_summary_day') ?? 28;

    final now = DateTime.now();
    var summaryDate = DateTime(now.year, now.month, summaryDay, 9, 0);
    if (summaryDate.isBefore(now)) {
      summaryDate = DateTime(now.year, now.month + 1, summaryDay, 9, 0);
    }
    final initialDelay = summaryDate.difference(now);

    await Workmanager().registerPeriodicTask(
      'bill_pit_monthly_summary',
      _taskMonthlySummary,
      frequency: const Duration(days: 1),
      initialDelay: initialDelay > Duration.zero ? initialDelay : const Duration(hours: 24),
    );

    await Workmanager().registerPeriodicTask(
      'bill_pit_weekly_preview',
      _taskWeeklyPreview,
      frequency: const Duration(hours: 12),
    );

    await Workmanager().registerPeriodicTask(
      'bill_pit_overdue_check',
      _taskOverdueCheck,
      frequency: const Duration(hours: 12),
    );

    await Workmanager().registerPeriodicTask(
      'bill_pit_value_check',
      _taskValueCheck,
      frequency: const Duration(hours: 12),
    );
  }

  static Future<void> setMonthlySummaryDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthly_summary_day', day);
  }

  static Future<int> getMonthlySummaryDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('monthly_summary_day') ?? 28;
  }
}

class NotificationChannel {
  final String id;
  final String name;
  final String description;
  const NotificationChannel({required this.id, required this.name, required this.description});
}
