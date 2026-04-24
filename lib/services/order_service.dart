import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../utils/constants.dart';
import 'api_config.dart';

class OrderService {
  OrderService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String _statusToBackend(OrderStatus status) {
    return switch (status) {
      OrderStatus.received => 'received',
      OrderStatus.preparing => 'preparing',
      OrderStatus.finished => 'finished',
      OrderStatus.delivered => 'delivered',
    };
  }

  Future<List<Order>> listOrders({
    required String token,
    List<OrderStatus>? statuses,
    int? tableNumber,
    String? comandaId,
    int? limit,
    int? page,
  }) async {
    final qp = <String, String>{};

    if (statuses != null && statuses.isNotEmpty) {
      qp['status'] = statuses.map(_statusToBackend).join(',');
    }

    if (tableNumber != null) qp['tableNumber'] = tableNumber.toString();
    if (comandaId != null && comandaId.isNotEmpty) qp['comandaId'] = comandaId;
    if (limit != null) qp['limit'] = limit.toString();
    if (page != null) qp['page'] = page.toString();

    final uri = Uri.parse('${ApiConfig.apiBase}/orders').replace(
      queryParameters: qp.isEmpty ? null : qp,
    );

    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final orders = body['orders'];
      if (orders is List) {
        return orders
            .whereType<Map>()
            .map((o) => Order.fromJson(_stringKeyMap(o)))
            .toList();
      }
      return <Order>[];
    }

    final msg = body['message']?.toString() ?? 'Erro ao listar pedidos';
    throw Exception(msg);
  }

  Future<Order> createOrder({required String token, required Order order}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/orders');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': order.id,
        'tableNumber': order.tableNumber,
        if (order.comandaId != null) 'comandaId': order.comandaId,
        'items': order.items.map((i) => i.toJson()).toList(),
        if (order.generalNotes != null) 'generalNotes': order.generalNotes,
      }),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = body['order'];
      if (raw is Map) {
        return Order.fromJson(_stringKeyMap(raw));
      }
      throw Exception('Resposta inválida ao criar pedido');
    }

    final msg = body['message']?.toString() ?? 'Erro ao criar pedido';
    throw Exception(msg);
  }

  Future<Order> updateOrderStatus({
    required String token,
    required String orderId,
    required OrderStatus status,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/orders/$orderId/status');

    final res = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': _statusToBackend(status)}),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = body['order'];
      if (raw is Map) {
        return Order.fromJson(_stringKeyMap(raw));
      }
      throw Exception('Resposta inválida ao atualizar pedido');
    }

    final msg = body['message']?.toString() ?? 'Erro ao atualizar pedido';
    throw Exception(msg);
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    if (res.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return _stringKeyMap(decoded);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _stringKeyMap(Map raw) {
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
}
