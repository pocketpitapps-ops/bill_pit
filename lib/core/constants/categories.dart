import 'package:flutter/material.dart';
import '../../data/models/expense.dart';

enum ExpenseCategory {
  housing,    // Casa
  vehicle,    // Veículo
  services,   // Serviço
  credit,     // Crédito
  health,     // Saúde
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
    Color(0xFF3B82F6),
  ),
  ExpenseCategory.vehicle: CategoryData(
    'Veículo',
    Icons.directions_car_outlined,
    Color(0xFF14B8A6),
  ),
  ExpenseCategory.services: CategoryData(
    'Serviço',
    Icons.build_outlined,
    Color(0xFFF59E0B),
  ),
  ExpenseCategory.credit: CategoryData(
    'Crédito',
    Icons.credit_card_outlined,
    Color(0xFFEF4444),
  ),
  ExpenseCategory.health: CategoryData(
    'Saúde',
    Icons.favorite_outline,
    Color(0xFF10B981),
  ),
};

const Map<ExpenseType, String> expenseTypeLabels = {
  ExpenseType.fixed: 'Fixa',
  ExpenseType.monthly: 'Fixa',
  ExpenseType.periodic: 'Periódica',
  ExpenseType.unique: 'Única',
};
