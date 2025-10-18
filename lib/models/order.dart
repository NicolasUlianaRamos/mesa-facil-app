import '../utils/constants.dart';
import 'order_item.dart';

class Order {
  final String id;
  final int tableNumber;
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
    return Order(
      id: json['id'] as String,
      tableNumber: json['tableNumber'] as int,
      items: (json['items'] as List)
          .map((item) {
            final m = (item as Map).map((k, v) => MapEntry(k.toString(), v));
            return OrderItem.fromJson(m);
          })
          .toList(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => OrderStatus.received,
      ),
      waiterId: json['waiterId'] as String,
      waiterName: json['waiterName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      generalNotes: json['generalNotes'] as String?,
      synced: json['synced'] as bool? ?? false,
    );
  }
}
