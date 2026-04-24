import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../utils/constants.dart';
import 'api_config.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> login({required String email, required String password}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users/login');

    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final token = body['token'];
      if (token is String && token.isNotEmpty) return token;
      throw Exception('Token não veio no login');
    }

    final msg = body['message']?.toString() ?? 'Erro ao fazer login';
    throw Exception(msg);
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users/register');

    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final token = body['token'];
      if (token is String && token.isNotEmpty) return token;
      throw Exception('Token não veio no register');
    }

    final msg = body['message']?.toString() ?? 'Erro ao registrar';
    throw Exception(msg);
  }

  Future<User> checkUser({required String token}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users/checkuser');

    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final rawUser = body['user'];
      if (rawUser is Map) {
        final userMap = rawUser.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendUser(userMap);
      }
      throw Exception('Resposta inválida do checkuser');
    }

    final msg = body['message']?.toString() ?? 'Sessão inválida';
    throw Exception(msg);
  }

  Future<User> checkUserAdmin({required String token}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users/checkuseradmin');

    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final rawUser = body['user'];
      if (rawUser is Map) {
        final userMap = rawUser.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendUser(userMap);
      }
      throw Exception('Resposta inválida do checkuseradmin');
    }

    final msg = body['message']?.toString() ?? 'Acesso de admin negado';
    throw Exception(msg);
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    if (res.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  User _mapBackendUser(Map<String, dynamic> user) {
    final id = (user['_id'] ?? user['id'] ?? '').toString();
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? '').toString();

    final mappedRole = switch (role) {
      'admin' => UserRole.admin,
      'kitchen' => UserRole.kitchen,
      // backend hoje tem user/admin; no app user vira waiter por enquanto
      _ => UserRole.waiter,
    };

    DateTime createdAt = DateTime.now();
    final rawCreatedAt = user['createdAt'];
    if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    return User(
      id: id,
      name: name.isEmpty ? email : name,
      username: email,
      password: '',
      role: mappedRole,
      createdAt: createdAt,
    );
  }
}
