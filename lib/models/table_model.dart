import '../utils/constants.dart';

class TableModel {
  final int number;
  TableStatus status;
  String? currentOrderId;
  double currentTotal;
  DateTime? occupiedSince;

  TableModel({
    required this.number,
    this.status = TableStatus.available,
    this.currentOrderId,
    this.currentTotal = 0.0,
    this.occupiedSince,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'status': status.toString(),
      'currentOrderId': currentOrderId,
      'currentTotal': currentTotal,
      'occupiedSince': occupiedSince?.toIso8601String(),
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
    );
  }
}
