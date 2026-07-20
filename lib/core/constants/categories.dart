import 'package:flutter/material.dart';
import '../../data/models/expense.dart';

enum ExpenseCategory {
  housing,      // Casa
  electricity,  // Electricidade
  water,        // Água
  gas,          // Gás
  vehicle,      // Veículo
  services,     // Serviço (subscrições)
  credit,       // Crédito
  health,       // Saúde
}

class CategoryData {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryData(this.name, this.icon, this.color);
}

const Map<ExpenseCategory, CategoryData> categories = {
  ExpenseCategory.housing: CategoryData('Casa', Icons.home_outlined, Color(0xFF3B82F6)),
  ExpenseCategory.electricity: CategoryData('Electricidade', Icons.bolt_outlined, Color(0xFFF59E0B)),
  ExpenseCategory.water: CategoryData('Água', Icons.water_outlined, Color(0xFF06B6D4)),
  ExpenseCategory.gas: CategoryData('Gás', Icons.local_fire_department_outlined, Color(0xFFF97316)),
  ExpenseCategory.vehicle: CategoryData('Veículo', Icons.directions_car_outlined, Color(0xFF14B8A6)),
  ExpenseCategory.services: CategoryData('Serviço', Icons.subscriptions_outlined, Color(0xFF8B5CF6)),
  ExpenseCategory.credit: CategoryData('Crédito', Icons.credit_card_outlined, Color(0xFFEF4444)),
  ExpenseCategory.health: CategoryData('Saúde', Icons.favorite_outline, Color(0xFF10B981)),
};

const Map<ExpenseType, String> expenseTypeLabels = {
  ExpenseType.fixed: 'Fixa',
  ExpenseType.monthly: 'Fixa',
  ExpenseType.periodic: 'Periódica',
  ExpenseType.unique: 'Única',
};
