import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../services/api_config.dart';
import '../utils/constants.dart';

class AdminUsersService {
  AdminUsersService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<User>> listUsers({required String token}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users');

    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = body['users'];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .map(_mapBackendUser)
            .toList();
      }
      return <User>[];
    }

    final msg = body['message']?.toString() ?? 'Erro ao listar usuários';
    throw Exception(msg);
  }

  Future<User> createUser({
    required String token,
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': _toBackendRole(role),
      }),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final rawUser = body['user'];
      if (rawUser is Map) {
        final userMap = rawUser.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendUser(userMap);
      }
      throw Exception('Resposta inválida ao criar usuário');
    }

    final msg = body['message']?.toString() ?? 'Erro ao criar usuário';
    throw Exception(msg);
  }

  Future<User> updateUser({
    required String token,
    required String userId,
    String? name,
    UserRole? role,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users/$userId');

    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (role != null) payload['role'] = _toBackendRole(role);

    final res = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final rawUser = body['user'];
      if (rawUser is Map) {
        final userMap = rawUser.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendUser(userMap);
      }
      throw Exception('Resposta inválida ao atualizar usuário');
    }

    final msg = body['message']?.toString() ?? 'Erro ao atualizar usuário';
    throw Exception(msg);
  }

  Future<void> deleteUser({
    required String token,
    required String userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/users/$userId');

    final res = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    final msg = body['message']?.toString() ?? 'Erro ao deletar usuário';
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

  String _toBackendRole(UserRole role) {
    return switch (role) {
      UserRole.admin => 'admin',
      UserRole.kitchen => 'kitchen',
      UserRole.waiter => 'user',
    };
  }
}
