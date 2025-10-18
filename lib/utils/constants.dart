import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E88E5);
  static const secondary = Color(0xFFFF6F00);
  static const accent = Color(0xFF5C6BC0);
  static const background = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);
  
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textLight = Colors.white;
}

enum OrderStatus {
  received,
  preparing,
  finished,
  delivered,
}

enum TableStatus {
  available,
  occupied,
  needsBill,
}

enum UserRole {
  waiter,
  kitchen,
  admin,
}

class OrderStatusHelper {
  static String getLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return 'Recebido';
      case OrderStatus.preparing:
        return 'Em Preparo';
      case OrderStatus.finished:
        return 'Finalizado';
      case OrderStatus.delivered:
        return 'Entregue';
    }
  }

  static Color getColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.warning;
      case OrderStatus.finished:
        return AppColors.success;
      case OrderStatus.delivered:
        return AppColors.accent;
    }
  }

  static IconData getIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return Icons.receipt;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.finished:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.done_all;
    }
  }
}

class TableStatusHelper {
  static String getLabel(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'Disponível';
      case TableStatus.occupied:
        return 'Ocupada';
      case TableStatus.needsBill:
        return 'Conta Solicitada';
    }
  }

  static Color getColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppColors.success;
      case TableStatus.occupied:
        return AppColors.warning;
      case TableStatus.needsBill:
        return AppColors.info;
    }
  }
}
