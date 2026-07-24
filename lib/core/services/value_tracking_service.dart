import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ValueTrackingService {
  static const _prefixUpdate = 'var_update_';
  static const _prefixHistory = 'var_history_';
  static const _maxHistory = 6;

  static Future<void> recordUpdate(int expenseId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString('$_prefixUpdate$expenseId', now);

    final history = await getHistory(expenseId);
    history.add(amount);
    if (history.length > _maxHistory) {
      history.removeAt(0);
    }
    await prefs.setString('$_prefixHistory$expenseId', jsonEncode(history));
  }

  static Future<DateTime?> getLastUpdateDate(int expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefixUpdate$expenseId');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<List<double>> getHistory(int expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefixHistory$expenseId');
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.cast<double>();
  }

  static Future<double?> getAverage(int expenseId) async {
    final history = await getHistory(expenseId);
    if (history.isEmpty) return null;
    final sum = history.fold<double>(0, (s, v) => s + v);
    return sum / history.length;
  }

  static Future<bool> needsUpdateThisMonth(int expenseId) async {
    final lastUpdate = await getLastUpdateDate(expenseId);
    if (lastUpdate == null) return true;
    final now = DateTime.now();
    return lastUpdate.year != now.year || lastUpdate.month != now.month;
  }

  static Future<Map<String, dynamic>> getExpenseReport(int expenseId) async {
    final lastUpdate = await getLastUpdateDate(expenseId);
    final average = await getAverage(expenseId);
    final needsUpdate = await needsUpdateThisMonth(expenseId);
    return {
      'lastUpdate': lastUpdate,
      'average': average,
      'needsUpdate': needsUpdate,
    };
  }
}
