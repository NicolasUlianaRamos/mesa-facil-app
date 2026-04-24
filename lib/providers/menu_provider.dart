import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/menu_item.dart';
import '../services/api_config.dart';
import '../services/storage_service.dart';
import '../services/menu_foods_service.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _menuItems = [];
  final MenuFoodsService _menuFoodsService = MenuFoodsService();
  io.Socket? _menuSocket;

  MenuProvider() {
    _loadMenu();
    unawaited(refreshMenuFromBackend());
    _connectMenuRealtime();
  }

  @override
  void dispose() {
    _menuSocket?.dispose();
    super.dispose();
  }

  List<MenuItem> get menuItems => _menuItems;

  List<MenuItem> get activeMenuItems =>
      _menuItems.where((item) => item.available).toList();

  List<String> get categories {
    return activeMenuItems.map((item) => item.category).toSet().toList();
  }

  List<MenuItem> getItemsByCategory(String category) {
    return activeMenuItems.where((item) => item.category == category).toList();
  }

  void _loadMenu() {
    _menuItems = StorageService.getMenuItems();
  }

  void _connectMenuRealtime() {
    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(500)
          .build(),
    );

    _menuSocket = socket;

    socket.onConnect((_) {
      socket.emit('menu:join');
    });

    socket.on('menu:updated', (dynamic data) {
      if (data is Map) {
        final id = (data['_id'] ?? data['id'] ?? '').toString();
        final isActive = data['isActive'] is bool ? data['isActive'] as bool : true;
        final idx = _menuItems.indexWhere((e) => e.id == id);
        if (idx != -1) {
          _menuItems[idx] = MenuItem(
            id: _menuItems[idx].id,
            name: _menuItems[idx].name,
            description: _menuItems[idx].description,
            price: _menuItems[idx].price,
            imageUrl: _menuItems[idx].imageUrl,
            category: _menuItems[idx].category,
            available: isActive,
          );
          unawaited(StorageService.replaceMenuItems(_menuItems));
          notifyListeners();
        }
      }
    });

    socket.connect();
  }

  Future<void> refreshMenuFromBackend() async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    final items = await _menuFoodsService.listMenuFoods(token: token);
    await StorageService.replaceMenuItems(items);
    _loadMenu();
    notifyListeners();
  }

  Future<void> addMenuItem(MenuItem item) async {
    await StorageService.saveMenuItem(item);
    _loadMenu();
    notifyListeners();
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await StorageService.saveMenuItem(item);
    _loadMenu();
    notifyListeners();
  }

  Future<void> toggleItemActive(String itemId) async {
    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) return;

    await _menuFoodsService.toggleMenuFoodActive(token: token, menuFoodId: itemId);
    // O refresh em tempo real virá pelo socket; força também para garantir consistência
    await refreshMenuFromBackend();
  }
}
