import '../utils/constants.dart';
import 'comanda.dart';

class TableModel {
  final int number;
  TableStatus status;
  String? currentOrderId;
  double currentTotal;
  DateTime? occupiedSince;
  List<Comanda> comandas;

  TableModel({
    required this.number,
    this.status = TableStatus.available,
    this.currentOrderId,
    this.currentTotal = 0.0,
    this.occupiedSince,
    List<Comanda>? comandas,
  }) : comandas = comandas ?? [];

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'status': status.toString(),
      'currentOrderId': currentOrderId,
      'currentTotal': currentTotal,
      'occupiedSince': occupiedSince?.toIso8601String(),
      'comandas': comandas.map((c) => c.toJson()).toList(),
    };
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      number: json['number'] as int,
      status: TableStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TableStatus.available,
      ),
      currentOrderId: json['currentOrderId'] as String?,
      currentTotal: (json['currentTotal'] as num?)?.toDouble() ?? 0.0,
      occupiedSince: json['occupiedSince'] != null
          ? DateTime.parse(json['occupiedSince'] as String)
          : null,
      comandas: json['comandas'] != null
          ? (json['comandas'] as List).map((c) {
              final m = (c as Map).map((k, v) => MapEntry(k.toString(), v));
              return Comanda.fromJson(m);
            }).toList()
          : [],
    );
  }
}
