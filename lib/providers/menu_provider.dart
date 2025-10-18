import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_item.dart';
import '../services/storage_service.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _menuItems = [];

  MenuProvider() {
    _loadMenu();
    _initializeDemoMenu();
  }

  List<MenuItem> get menuItems => _menuItems;

  List<String> get categories {
    return _menuItems.map((item) => item.category).toSet().toList();
  }

  List<MenuItem> getItemsByCategory(String category) {
    return _menuItems.where((item) => item.category == category).toList();
  }

  void _loadMenu() {
    _menuItems = StorageService.getMenuItems();
  }

  Future<void> _initializeDemoMenu() async {
    if (_menuItems.isEmpty) {
      final demoItems = [
        MenuItem(
          id: const Uuid().v4(),
          name: 'Pizza Margherita',
          description: 'Molho de tomate, mussarela e manjericão fresco',
          price: 45.90,
          imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=800&auto=format&fit=crop',
          category: 'Pizzas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Pizza Calabresa',
          description: 'Calabresa, mussarela, cebola e orégano',
          price: 48.90,
          imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=800&auto=format&fit=crop',
          category: 'Pizzas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Pizza Portuguesa',
          description: 'Presunto, ovos, cebola, azeitona e mussarela',
          price: 52.90,
          imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=800&auto=format&fit=crop',
          category: 'Pizzas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Coca-Cola 2L',
          description: 'Refrigerante Coca-Cola 2 litros',
          price: 12.90,
          imageUrl: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?q=80&w=800&auto=format&fit=crop',
          category: 'Bebidas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Guaraná Antarctica 2L',
          description: 'Refrigerante Guaraná 2 litros',
          price: 11.90,
          imageUrl: 'https://images.unsplash.com/photo-1581006852262-e4307cf6283a?q=80&w=800&auto=format&fit=crop',
          category: 'Bebidas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Suco Natural Laranja',
          description: 'Suco de laranja natural 500ml',
          price: 8.90,
          imageUrl: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?q=80&w=800&auto=format&fit=crop',
          category: 'Bebidas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Pudim de Leite',
          description: 'Tradicional pudim de leite condensado',
          price: 15.90,
          imageUrl: 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?q=80&w=800&auto=format&fit=crop',
          category: 'Sobremesas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Brownie com Sorvete',
          description: 'Brownie de chocolate com sorvete de baunilha',
          price: 18.90,
          imageUrl: 'https://images.unsplash.com/photo-1607920591413-4ec007e70023?q=80&w=800&auto=format&fit=crop',
          category: 'Sobremesas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Salada Caesar',
          description: 'Alface, croutons, parmesão e molho caesar',
          price: 28.90,
          imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?q=80&w=800&auto=format&fit=crop',
          category: 'Saladas',
        ),
        MenuItem(
          id: const Uuid().v4(),
          name: 'Hambúrguer Artesanal',
          description: 'Pão artesanal, hambúrguer 180g, queijo e salada',
          price: 35.90,
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=800&auto=format&fit=crop',
          category: 'Lanches',
        ),
      ];

      for (var item in demoItems) {
        await StorageService.saveMenuItem(item);
      }

      _loadMenu();
      notifyListeners();
    }
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
}
