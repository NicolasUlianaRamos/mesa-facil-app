import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/table_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<TableModel> _tables = [];

  OrderProvider() {
    _loadData();
    _initializeTables();
  }

  List<Order> get orders => _orders;
  List<TableModel> get tables => _tables;

  List<Order> get activeOrders {
    return _orders.where((order) => order.status != OrderStatus.delivered).toList();
  }

  List<Order> getOrdersByTable(int tableNumber) {
    // Show only orders for the current occupancy/session
    final table = getTable(tableNumber);
    if (table == null) return [];
    if (table.status == TableStatus.available) return [];

    final since = table.occupiedSince;
    return _orders.where((order) {
      if (order.tableNumber != tableNumber) return false;
      if (since == null) return true; // fallback if not set
      return order.createdAt.isAtSameMomentAs(since) || order.createdAt.isAfter(since);
    }).toList();
  }

  TableModel? getTable(int number) {
    try {
      return _tables.firstWhere((table) => table.number == number);
    } catch (e) {
      return null;
    }
  }

  void _loadData() {
    _orders = StorageService.getOrders();
    _tables = StorageService.getTables();
  }

  Future<void> _initializeTables() async {
    if (_tables.isEmpty) {
      for (int i = 1; i <= 20; i++) {
        final table = TableModel(number: i);
        await StorageService.saveTable(table);
      }
      _loadData();
      notifyListeners();
    }
  }

  Future<void> addOrder(Order order) async {
    await StorageService.saveOrder(order);
    
    final table = getTable(order.tableNumber);
    if (table != null) {
      table.status = TableStatus.occupied;
      table.currentOrderId = order.id;
  // Start a new occupancy window at the time of the first order
  table.occupiedSince ??= order.createdAt;
      await StorageService.saveTable(table);
    }
    
    _loadData();
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    order.status = newStatus;

    switch (newStatus) {
      case OrderStatus.preparing:
        order.startedAt = DateTime.now();
        break;
      case OrderStatus.finished:
        order.finishedAt = DateTime.now();
        break;
      case OrderStatus.delivered:
        order.deliveredAt = DateTime.now();
        break;
      default:
        break;
    }

    await StorageService.saveOrder(order);
    _loadData();
    notifyListeners();
  }

  Future<void> finalizeCustomerAtTable(int tableNumber) async {
    // Mark all orders from this table as delivered
    final tableOrders = _orders
        .where((o) => o.tableNumber == tableNumber && o.status != OrderStatus.delivered)
        .toList();
    for (final o in tableOrders) {
      o.status = OrderStatus.delivered;
      o.deliveredAt = DateTime.now();
      await StorageService.saveOrder(o);
    }

    // Free the table
    final table = getTable(tableNumber);
    if (table != null) {
      table.status = TableStatus.available;
      table.currentOrderId = null;
      table.currentTotal = 0.0;
      table.occupiedSince = null;
      await StorageService.saveTable(table);
    }

    _loadData();
    notifyListeners();
  }

  Future<void> updateTableStatus(int tableNumber, TableStatus newStatus) async {
    final table = getTable(tableNumber);
    if (table != null) {
      table.status = newStatus;
      
      if (newStatus == TableStatus.available) {
        table.currentOrderId = null;
        table.currentTotal = 0.0;
        table.occupiedSince = null;
      }
      
      await StorageService.saveTable(table);
      _loadData();
      notifyListeners();
    }
  }

  double getTableTotal(int tableNumber) {
    // Sum only orders from the current session (visible to the waiter)
    final tableOrders = getOrdersByTable(tableNumber);
    return tableOrders.fold(0.0, (sum, order) => sum + order.total);
  }
}
