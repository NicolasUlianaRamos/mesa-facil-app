class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }
}
