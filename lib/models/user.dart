import '../utils/constants.dart';

class User {
  final String id;
  final String name;
  final String username;
  final String password;
  final UserRole role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.waiter,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
