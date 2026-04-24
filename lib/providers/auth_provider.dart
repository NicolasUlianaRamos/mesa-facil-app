import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

enum AuthState { initializing, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final AuthService _authService = AuthService();

  String? _token;
  AuthState _state = AuthState.initializing;
  bool _busy = false;
  String? _lastError;

  // Mantido por compatibilidade com telas existentes
  final List<User> _users = [];

  AuthProvider() {
    _bootstrap();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<User> get users => _users;

  AuthState get state => _state;
  bool get isInitializing => _state == AuthState.initializing;
  bool get isBusy => _busy;
  String? get token => _token;
  String? get lastError => _lastError;

  Future<void> _bootstrap() async {
    _state = AuthState.initializing;
    notifyListeners();

    _token = StorageService.getAuthToken();
    _currentUser = StorageService.getCurrentAuthUser();

    if (_token != null && _token!.isNotEmpty) {
      final ok = await checkUser();
      _state = ok ? AuthState.authenticated : AuthState.unauthenticated;
    } else {
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  /// Mantive a assinatura (username/password) pra não quebrar telas.
  /// Aqui `username` é tratado como email.
  Future<bool> login(String username, String password) async {
    if (_busy) return false;
    _busy = true;
    _lastError = null;
    notifyListeners();

    try {
      final token = await _authService.login(email: username, password: password);
      _token = token;
      await StorageService.saveAuthToken(token);

      final user = await _authService.checkUser(token: token);
      _currentUser = user;
      await StorageService.saveCurrentAuthUser(user);

      _state = AuthState.authenticated;
      return true;
    } catch (e) {
      _lastError = e.toString();
      await StorageService.clearAuth();
      _token = null;
      _currentUser = null;
      _state = AuthState.unauthenticated;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _state = AuthState.unauthenticated;
    await StorageService.clearAuth();
    notifyListeners();
  }

  /// Verifica a sessão no backend via `/api/users/checkuser`.
  /// Retorna `true` se token for válido, senão faz logout e retorna `false`.
  Future<bool> checkUser() async {
    final token = _token ?? StorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      await logout();
      return false;
    }

    try {
      _lastError = null;
      final user = await _authService.checkUser(token: token);
      _token = token;
      _currentUser = user;
      await StorageService.saveCurrentAuthUser(user);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      await logout();
      return false;
    }
  }

  /// Verifica se o usuário logado é admin via `/api/users/checkuseradmin`.
  /// Retorna `true` se válido (e admin), senão faz logout.
  Future<bool> checkAdminUser() async {
    final token = _token ?? StorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      await logout();
      return false;
    }

    try {
      _lastError = null;
      final user = await _authService.checkUserAdmin(token: token);
      _token = token;
      _currentUser = user;
      await StorageService.saveCurrentAuthUser(user);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      await logout();
      return false;
    }
  }
}
