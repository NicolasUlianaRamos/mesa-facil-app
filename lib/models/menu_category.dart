class MenuCategory {
  const MenuCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    return MenuCategory(id: id, name: name);
  }
}
