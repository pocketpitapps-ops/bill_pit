import 'package:shared_preferences/shared_preferences.dart';

class OnboardingConfig {
  static const String _key = 'has_seen_onboarding';

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
