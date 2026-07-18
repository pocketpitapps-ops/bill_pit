// lib/core/constants/categories.dart
import 'package:flutter/material.dart';
import '../../data/models/expense.dart';

enum ExpenseCategory {
  housing,    // Casa
  transport,  // Transporte
  services,   // Serviços
  health,     // Saúde
  education,  // Educação
  food,       // Alimentação
  leisure,    // Lazer
  other,      // Outro
}

class CategoryData {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryData(this.name, this.icon, this.color);
}

const Map<ExpenseCategory, CategoryData> categories = {
  ExpenseCategory.housing: CategoryData(
    'Casa',
    Icons.home_outlined,
    Color(0xFF6366F1),
  ),
  ExpenseCategory.transport: CategoryData(
    'Transporte',
    Icons.directions_car_outlined,
    Color(0xFF3B82F6),
  ),
  ExpenseCategory.services: CategoryData(
    'Serviços',
    Icons.bolt_outlined,
    Color(0xFFF59E0B),
  ),
  ExpenseCategory.health: CategoryData(
    'Saúde',
    Icons.favorite_outline,
    Color(0xFFEF4444),
  ),
  ExpenseCategory.education: CategoryData(
    'Educação',
    Icons.school_outlined,
    Color(0xFF8B5CF6),
  ),
  ExpenseCategory.food: CategoryData(
    'Alimentação',
    Icons.restaurant_outlined,
    Color(0xFF10B981),
  ),
  ExpenseCategory.leisure: CategoryData(
    'Lazer',
    Icons.sports_esports_outlined,
    Color(0xFFEC4899),
  ),
  ExpenseCategory.other: CategoryData(
    'Outro',
    Icons.more_horiz,
    Color(0xFF64748B),
  ),
};

const Map<ExpenseType, String> expenseTypeLabels = {
  ExpenseType.fixed: 'Fixa',
  ExpenseType.monthly: 'Mensal',
  ExpenseType.periodic: 'Periódica',
  ExpenseType.unique: 'Única',
};
