import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/comanda.dart';
import '../models/table_model.dart';
import '../utils/constants.dart';
import 'api_config.dart';

class TableService {
  TableService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  TableStatus _parseStatus(dynamic raw) {
    final s = (raw ?? '').toString();
    return switch (s) {
      'available' => TableStatus.available,
      'occupied' => TableStatus.occupied,
      'needsBill' => TableStatus.needsBill,
      _ => TableStatus.available,
    };
  }

  Future<List<TableModel>> listTables({required String token}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/tables');

    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final tables = body['tables'];
      if (tables is List) {
        return tables
            .whereType<Map>()
            .map(
              (t) =>
                  _mapBackendTable(t.map((k, v) => MapEntry(k.toString(), v))),
            )
            .toList();
      }
      return <TableModel>[];
    }

    final msg = body['message']?.toString() ?? 'Erro ao listar mesas';
    throw Exception(msg);
  }

  Future<int> createTable({required String token, int? number}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/tables');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({if (number != null) 'number': number}),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final table = body['table'];
      if (table is Map) {
        final map = table.map((k, v) => MapEntry(k.toString(), v));
        final raw = map['number'];
        final n = raw is num ? raw.toInt() : int.tryParse(raw.toString());
        if (n != null) return n;
      }
      throw Exception('Resposta inválida ao criar mesa');
    }

    final msg = body['message']?.toString() ?? 'Erro ao criar mesa';
    throw Exception(msg);
  }

  Future<TableModel> occupyTable({
    required String token,
    required int tableNumber,
    required List<Comanda> comandas,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/tables/$tableNumber/occupy');

    final res = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'comandas': comandas
            .map(
              (c) => {
                'id': c.id,
                'name': c.name,
                'createdAt': c.createdAt.toIso8601String(),
              },
            )
            .toList(),
      }),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final table = body['table'];
      if (table is Map) {
        final map = table.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendTable(map);
      }
      throw Exception('Resposta inválida ao ocupar mesa');
    }

    final msg = body['message']?.toString() ?? 'Erro ao ocupar mesa';
    throw Exception(msg);
  }

  Future<TableModel> freeTable({
    required String token,
    required int tableNumber,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/tables/$tableNumber/free');

    final res = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final table = body['table'];
      if (table is Map) {
        final map = table.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendTable(map);
      }
      throw Exception('Resposta inválida ao liberar mesa');
    }

    final msg = body['message']?.toString() ?? 'Erro ao liberar mesa';
    throw Exception(msg);
  }

  Future<TableModel> addComanda({
    required String token,
    required int tableNumber,
    required Comanda comanda,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/tables/$tableNumber/comandas');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': comanda.id,
        'name': comanda.name,
        'createdAt': comanda.createdAt.toIso8601String(),
      }),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final table = body['table'];
      if (table is Map) {
        final map = table.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendTable(map);
      }
      throw Exception('Resposta inválida ao adicionar comanda');
    }

    final msg = body['message']?.toString() ?? 'Erro ao adicionar comanda';
    throw Exception(msg);
  }

  Future<TableModel> removeComanda({
    required String token,
    required int tableNumber,
    required String comandaId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.apiBase}/tables/$tableNumber/comandas/$comandaId',
    );

    final res = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final table = body['table'];
      if (table is Map) {
        final map = table.map((k, v) => MapEntry(k.toString(), v));
        return _mapBackendTable(map);
      }
      throw Exception('Resposta inválida ao remover comanda');
    }

    final msg = body['message']?.toString() ?? 'Erro ao remover comanda';
    throw Exception(msg);
  }

  TableModel _mapBackendTable(Map<String, dynamic> map) {
    final numberRaw = map['number'];
    final number = numberRaw is num
        ? numberRaw.toInt()
        : int.tryParse(numberRaw.toString()) ?? 0;

    final rawComandas = map['comandas'];
    final comandas = rawComandas is List
        ? rawComandas.whereType<Map>().map((c) {
            final cm = c.map((k, v) => MapEntry(k.toString(), v));
            return Comanda(
              id: (cm['id'] ?? '').toString(),
              tableNumber: number,
              name: (cm['name'] ?? '').toString(),
              createdAt: cm['createdAt'] is String
                  ? (DateTime.tryParse(cm['createdAt'] as String) ??
                        DateTime.now())
                  : DateTime.now(),
            );
          }).toList()
        : <Comanda>[];

    return TableModel(
      number: number,
      status: _parseStatus(map['status']),
      occupiedSince: map['occupiedSince'] is String
          ? DateTime.tryParse(map['occupiedSince'] as String)
          : null,
      comandas: comandas,
    );
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
}
