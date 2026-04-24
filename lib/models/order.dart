import '../utils/constants.dart';
import 'order_item.dart';

class Order {
  final String id;
  final int tableNumber;
  final String? comandaId;
  final List<OrderItem> items;
  OrderStatus status;
  final String waiterId;
  final String waiterName;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? finishedAt;
  DateTime? deliveredAt;
  final String? generalNotes;
  bool synced;

  Order({
    required this.id,
    required this.tableNumber,
    this.comandaId,
    required this.items,
    this.status = OrderStatus.received,
    required this.waiterId,
    required this.waiterName,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.deliveredAt,
    this.generalNotes,
    this.synced = false,
  });

  double get total {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'comandaId': comandaId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString(),
      'waiterId': waiterId,
      'waiterName': waiterName,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'generalNotes': generalNotes,
      'synced': synced,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['_id'] ?? '').toString();

    final tableNumberRaw = json['tableNumber'];
    final tableNumber = tableNumberRaw is num
        ? tableNumberRaw.toInt()
        : int.tryParse((tableNumberRaw ?? '0').toString()) ?? 0;

    final rawStatus = (json['status'] ?? '').toString();
    final normalizedStatus = switch (rawStatus) {
      'received' => OrderStatus.received,
      'preparing' => OrderStatus.preparing,
      'finished' => OrderStatus.finished,
      'delivered' => OrderStatus.delivered,
      _ => null,
    };

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : DateTime.tryParse(s);
    }

    final rawItems = json['items'];
    final itemsList = rawItems is List ? rawItems : const [];

    return Order(
      id: rawId,
      tableNumber: tableNumber,
      comandaId: json['comandaId'] as String?,
      items: itemsList.whereType<Map>().map((item) {
        final m = item.map((k, v) => MapEntry(k.toString(), v));
        return OrderItem.fromJson(m);
      }).toList(),
      status:
          normalizedStatus ??
          OrderStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
            orElse: () => OrderStatus.received,
          ),
      waiterId: (json['waiterId'] ?? '').toString(),
      waiterName: (json['waiterName'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      startedAt: parseDate(json['startedAt']),
      finishedAt: parseDate(json['finishedAt']),
      deliveredAt: parseDate(json['deliveredAt']),
      generalNotes: json['generalNotes'] as String?,
      synced: json['synced'] as bool? ?? false,
    );
  }
}
