// lib/models/user.dart

class User {
  final int id;
  final String username;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id:          json['id']        as int,
        username:    json['username']  as String,
        role:        json['role']      as String,
        createdAt:   DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(
            (json['updatedAt'] as String?) ?? (json['createdAt'] as String)
        ),
      );
}
