class TableFinalizationEvent {
  final String id;
  final int tableNumber;
  final DateTime finalizedAt;

  TableFinalizationEvent({
    required this.id,
    required this.tableNumber,
    required this.finalizedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'finalizedAt': finalizedAt.toIso8601String(),
    };
  }

  factory TableFinalizationEvent.fromJson(Map<String, dynamic> json) {
    return TableFinalizationEvent(
      id: json['id'] as String,
      tableNumber: json['tableNumber'] as int,
      finalizedAt: DateTime.parse(json['finalizedAt'] as String),
    );
  }
}
