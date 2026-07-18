import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppCategory {
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;

  const AppCategory({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'isDefault': isDefault,
      };

  factory AppCategory.fromJson(Map<String, dynamic> json) => AppCategory(
        name: json['name'] as String,
        iconCodePoint: json['iconCodePoint'] as int,
        colorValue: json['colorValue'] as int,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  AppCategory copyWith({String? name, int? iconCodePoint, int? colorValue}) => AppCategory(
        name: name ?? this.name,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        colorValue: colorValue ?? this.colorValue,
        isDefault: isDefault,
      );
}

class CategoryService extends ChangeNotifier {
  static const _prefsKey = 'app_categories';
  List<AppCategory> _categories = [];

  List<AppCategory> get categories => List.unmodifiable(_categories);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _categories = decoded.map((e) => AppCategory.fromJson(e)).toList();
    } else {
      _categories = _defaults();
      await _save();
    }
  }

  Future<void> add(String name, IconData icon, Color color) async {
    _categories.add(AppCategory(
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color.toARGB32(),
    ));
    await _save();
    notifyListeners();
  }

  Future<void> update(String oldName, {required String name, required IconData icon, required Color color}) async {
    final idx = _categories.indexWhere((c) => c.name == oldName);
    if (idx == -1) return;
    _categories[idx] = _categories[idx].copyWith(
      name: name,
      iconCodePoint: icon.codePoint,
      colorValue: color.toARGB32(),
    );
    await _save();
    notifyListeners();
  }

  Future<bool> delete(String name) async {
    final idx = _categories.indexWhere((c) => c.name == name);
    if (idx == -1) return false;
    _categories.removeAt(idx);
    await _save();
    notifyListeners();
    return true;
  }

  Future<bool> rename(String oldName, String newName) async {
    if (_categories.any((c) => c.name != oldName && c.name == newName)) return false;
    final idx = _categories.indexWhere((c) => c.name == oldName);
    if (idx == -1) return false;
    _categories[idx] = _categories[idx].copyWith(name: newName);
    await _save();
    notifyListeners();
    return true;
  }

  AppCategory? findByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  List<AppCategory> get defaults => _categories.where((c) => c.isDefault).toList();
  List<AppCategory> get custom => _categories.where((c) => !c.isDefault).toList();

  Future<void> reset() async {
    _categories = _defaults();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_categories.map((c) => c.toJson()).toList()));
  }

  static List<AppCategory> _defaults() => const [
        AppCategory(name: 'Casa', iconCodePoint: 0xe559, colorValue: 0xFF6366F1, isDefault: true),
        AppCategory(name: 'Transporte', iconCodePoint: 0xe531, colorValue: 0xFF3B82F6, isDefault: true),
        AppCategory(name: 'Serviços', iconCodePoint: 0xe56c, colorValue: 0xFFF59E0B, isDefault: true),
        AppCategory(name: 'Saúde', iconCodePoint: 0xe548, colorValue: 0xFFEF4444, isDefault: true),
        AppCategory(name: 'Educação', iconCodePoint: 0xe553, colorValue: 0xFF8B5CF6, isDefault: true),
        AppCategory(name: 'Alimentação', iconCodePoint: 0xe553, colorValue: 0xFF10B981, isDefault: true),
        AppCategory(name: 'Lazer', iconCodePoint: 0xe5a0, colorValue: 0xFFEC4899, isDefault: true),
        AppCategory(name: 'Outro', iconCodePoint: 0xe567, colorValue: 0xFF64748B, isDefault: true),
      ];
}
