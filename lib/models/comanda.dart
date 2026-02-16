class Comanda {
  final String id;
  final int tableNumber;
  final String name;
  final DateTime createdAt;

  Comanda({
    required this.id,
    required this.tableNumber,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Comanda.fromJson(Map<String, dynamic> json) {
    return Comanda(
      id: json['id'] as String,
      tableNumber: json['tableNumber'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
