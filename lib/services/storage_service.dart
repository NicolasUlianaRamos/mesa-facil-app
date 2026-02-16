import 'package:hive_flutter/hive_flutter.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/table_model.dart';
import '../models/user.dart';
import '../models/message.dart';

class StorageService {
  static const String _ordersBox = 'orders';
  static const String _menuBox = 'menu';
  static const String _tablesBox = 'tables';
  static const String _usersBox = 'users';
  static const String _messagesBox = 'messages';

  static Future<void> init() async {
    await Hive.openBox(_ordersBox);
    await Hive.openBox(_menuBox);
    await Hive.openBox(_tablesBox);
    await Hive.openBox(_usersBox);
    await Hive.openBox(_messagesBox);
  }

  static Box get _orders => Hive.box(_ordersBox);
  static Box get _menu => Hive.box(_menuBox);
  static Box get _tables => Hive.box(_tablesBox);
  static Box get _users => Hive.box(_usersBox);
  static Box get _messages => Hive.box(_messagesBox);

  // Orders
  static Future<void> saveOrder(Order order) async {
    await _orders.put(order.id, order.toJson());
  }

  static Future<void> deleteOrder(String orderId) async {
    await _orders.delete(orderId);
  }

  static List<Order> getOrders() {
    return _orders.values.map((json) {
      final map = (json as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return Order.fromJson(map);
    }).toList();
  }

  // Menu Items
  static Future<void> saveMenuItem(MenuItem item) async {
    await _menu.put(item.id, item.toJson());
  }

  static List<MenuItem> getMenuItems() {
    return _menu.values.map((json) {
      final map = (json as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return MenuItem.fromJson(map);
    }).toList();
  }

  // Tables
  static Future<void> saveTable(TableModel table) async {
    await _tables.put(table.number, table.toJson());
  }

  static List<TableModel> getTables() {
    return _tables.values.map((json) {
      final map = (json as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return TableModel.fromJson(map);
    }).toList();
  }

  // Users
  static Future<void> saveUser(User user) async {
    await _users.put(user.id, user.toJson());
  }

  static List<User> getUsers() {
    return _users.values.map((json) {
      final map = (json as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return User.fromJson(map);
    }).toList();
  }

  // Messages
  static Future<void> saveMessage(Message message) async {
    await _messages.put(message.id, message.toJson());
  }

  static List<Message> getMessages() {
    return _messages.values.map((json) {
      final map = (json as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return Message.fromJson(map);
    }).toList();
  }

  static Future<void> clearAll() async {
    await _orders.clear();
    await _menu.clear();
    await _tables.clear();
    await _users.clear();
    await _messages.clear();
  }
}
