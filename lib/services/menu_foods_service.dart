import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/menu_category.dart';
import '../models/menu_item.dart';
import 'api_config.dart';

class MenuFoodsService {
  MenuFoodsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<MenuItem>> listMenuFoods({
    required String token,
    String? category,
    bool? isActive,
  }) async {
    final qp = <String, String>{};
    if (category != null && category.isNotEmpty) qp['category'] = category;
    if (isActive != null) qp['isActive'] = isActive.toString();

    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods/foods').replace(
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
      final items = body['menuFoods'];
      if (items is List) {
        return items.whereType<Map>().map((raw) {
          final map = raw.map((k, v) => MapEntry(k.toString(), v));
          final id = (map['_id'] ?? map['id'] ?? '').toString();
          final name = (map['name'] ?? '').toString();
          final description = (map['description'] ?? '').toString();
          final category = (map['category'] ?? '').toString();
          final imageUrl = _normalizeImageUrl((map['imageUrl'] ?? '').toString());
          final price = (map['price'] as num?)?.toDouble() ??
              double.tryParse((map['price'] ?? '0').toString()) ??
              0.0;
          final available = map['isActive'] is bool ? map['isActive'] as bool : true;

          return MenuItem(
            id: id,
            name: name,
            description: description,
            price: price,
            imageUrl: imageUrl,
            category: category,
            available: available,
          );
        }).toList();
      }
      return <MenuItem>[];
    }

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao listar cardápio',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Future<List<MenuCategory>> listMenuCategories({required String token}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods/categories');

    final res = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = body['categories'];
      if (raw is List) {
        return raw.whereType<Map>().map((e) {
          final map = e.map((k, v) => MapEntry(k.toString(), v));
          return MenuCategory.fromJson(map);
        }).toList();
      }
      return <MenuCategory>[];
    }

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao listar categorias',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Future<MenuCategory> createMenuCategory({
    required String token,
    required String name,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods/categories');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = body['category'];
      if (raw is Map) {
        final map = raw.map((k, v) => MapEntry(k.toString(), v));
        return MenuCategory.fromJson(map);
      }
      throw Exception('Resposta inválida ao criar categoria');
    }

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao criar categoria',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Future<void> deleteMenuCategory({
    required String token,
    required String categoryId,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods/categories/$categoryId');

    final res = await _client.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao deletar categoria',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Future<MenuItem> createMenuFood({
    required String token,
    required String name,
    required String description,
    required double price,
    required String category,
    required String imageUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        // backend expects `imageurl`
        'imageurl': imageUrl,
      }),
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = body['menuFood'];
      if (raw is Map) {
        final map = raw.map((k, v) => MapEntry(k.toString(), v));
        final id = (map['_id'] ?? map['id'] ?? '').toString();
        final available = map['isActive'] is bool ? map['isActive'] as bool : true;
        return MenuItem(
          id: id,
          name: (map['name'] ?? '').toString(),
          description: (map['description'] ?? '').toString(),
          price: (map['price'] as num?)?.toDouble() ??
              double.tryParse((map['price'] ?? '0').toString()) ??
              0.0,
          imageUrl: _normalizeImageUrl((map['imageUrl'] ?? '').toString()),
          category: (map['category'] ?? '').toString(),
          available: available,
        );
      }
      throw Exception('Resposta inválida ao criar item do cardápio');
    }

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao criar item do cardápio',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Future<MenuItem> createMenuFoodWithImage({
    required String token,
    required String name,
    required String description,
    required double price,
    required String category,
    required XFile image,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $token';

    req.fields['name'] = name;
    req.fields['description'] = description;
    req.fields['price'] = price.toString();
    req.fields['category'] = category;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      final mediaType = _guessMediaTypeFromName(image.name);
      req.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name,
          contentType: mediaType,
        ),
      );
    } else {
      req.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = body['menuFood'];
      if (raw is Map) {
        final map = raw.map((k, v) => MapEntry(k.toString(), v));
        final id = (map['_id'] ?? map['id'] ?? '').toString();
        final available = map['isActive'] is bool ? map['isActive'] as bool : true;
        return MenuItem(
          id: id,
          name: (map['name'] ?? '').toString(),
          description: (map['description'] ?? '').toString(),
          price: (map['price'] as num?)?.toDouble() ??
              double.tryParse((map['price'] ?? '0').toString()) ??
              0.0,
          imageUrl: _normalizeImageUrl((map['imageUrl'] ?? '').toString()),
          category: (map['category'] ?? '').toString(),
          available: available,
        );

      }
      throw Exception('Resposta inválida ao criar item do cardápio');
    }

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao criar item do cardápio',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Future<void> toggleMenuFoodActive({
    required String token,
    required String menuFoodId,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods/foods/$menuFoodId/active');

    final res = await _client.patch(
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

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao alterar status do item',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Future<void> deleteMenuFood({
    required String token,
    required String menuFoodId,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/menufoods/foods/$menuFoodId');

    final res = await _client.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = _decodeJson(res);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    throw Exception(_extractErrorMessage(
      body,
      fallback: 'Erro ao deletar item do cardápio',
      statusCode: res.statusCode,
      rawBody: res.body,
    ));
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    if (res.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
      return <String, dynamic>{};
    } catch (_) {
      // backend might send plain text / html on unexpected errors
      return <String, dynamic>{'_raw': res.body};
    }
  }

  String _extractErrorMessage(
    Map<String, dynamic> body, {
    required String fallback,
    required int statusCode,
    required String rawBody,
  }) {
    final fromMessage = (body['message'] ?? body['error'] ?? body['detail'])?.toString().trim();
    if (fromMessage != null && fromMessage.isNotEmpty && fromMessage != 'null') {
      return fromMessage;
    }

    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      // handle express-validator format: [{ field: 'msg' }, ...]
      final first = errors.first;
      if (first is Map) {
        final values = first.values.map((v) => v.toString()).where((s) => s.trim().isNotEmpty);
        final msg = values.isEmpty ? null : values.first.trim();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      return 'Erro de validação (${errors.length})';
    }

    final raw = (body['_raw'] ?? rawBody).toString().trim();
    if (raw.isNotEmpty && raw != 'null') {
      // avoid dumping huge HTML; keep it short
      final shortened = raw.length > 300 ? '${raw.substring(0, 300)}...' : raw;
      return shortened;
    }

    return '$fallback (HTTP $statusCode)';
  }

  String _normalizeImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) return '${ApiConfig.baseUrl}$trimmed';
    return '${ApiConfig.baseUrl}/$trimmed';
  }

  MediaType _guessMediaTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.heic')) return MediaType('image', 'heic');
    if (lower.endsWith('.heif')) return MediaType('image', 'heif');
    // default jpeg for .jpg/.jpeg and unknowns
    return MediaType('image', 'jpeg');
  }
}
