import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  List<User> _users = [];

  AuthProvider() {
    _loadUsers();
    _initializeDemoUsers();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<User> get users => _users;

  void _loadUsers() {
    _users = StorageService.getUsers();
  }

  Future<void> _initializeDemoUsers() async {
    if (_users.isEmpty) {
      final demoUsers = [
        User(
          id: const Uuid().v4(),
          name: 'João Silva',
          username: 'garcom',
          password: '123',
          role: UserRole.waiter,
          createdAt: DateTime.now(),
        ),
        User(
          id: const Uuid().v4(),
          name: 'Maria Santos',
          username: 'cozinha',
          password: '123',
          role: UserRole.kitchen,
          createdAt: DateTime.now(),
        ),
        User(
          id: const Uuid().v4(),
          name: 'Admin',
          username: 'admin',
          password: '123',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        ),
      ];

      for (var user in demoUsers) {
        await StorageService.saveUser(user);
      }

      _loadUsers();
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final user = _users.firstWhere(
        (u) => u.username == username && u.password == password,
      );

      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> addUser(User user) async {
    await StorageService.saveUser(user);
    _loadUsers();
    notifyListeners();
  }
}
