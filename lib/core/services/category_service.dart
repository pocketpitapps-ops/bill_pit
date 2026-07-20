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

  bool nameExists(String name) => _categories.any((c) => c.name.toLowerCase() == name.toLowerCase());

  List<int> get usedIconCodePoints => _categories.map((c) => c.iconCodePoint).toList();

  List<int> get usedColorValues => _categories.map((c) => c.colorValue).toList();

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
        AppCategory(name: 'Casa', iconCodePoint: 0xf107, colorValue: 0xFF22C55E, isDefault: true),
        AppCategory(name: 'Electricidade', iconCodePoint: 0xeedd, colorValue: 0xFFF59E0B, isDefault: true),
        AppCategory(name: 'Água', iconCodePoint: 0xf4b4, colorValue: 0xFF3B82F6, isDefault: true),
        AppCategory(name: 'Gás', iconCodePoint: 0xf17a, colorValue: 0xFFF97316, isDefault: true),
        AppCategory(name: 'Veículo', iconCodePoint: 0xefc6, colorValue: 0xFFFFFFFF, isDefault: true),
        AppCategory(name: 'Subscrições', iconCodePoint: 0xf3fb, colorValue: 0xFF8B5CF6, isDefault: true),
        AppCategory(name: 'Crédito', iconCodePoint: 0xef8f, colorValue: 0xFFEF4444, isDefault: true),
        AppCategory(name: 'Saúde', iconCodePoint: 0xe25c, colorValue: 0xFFEC4899, isDefault: true),
        AppCategory(name: 'Outros', iconCodePoint: 0xe5d3, colorValue: 0xFF64748B, isDefault: true),
      ];
}
