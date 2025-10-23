class User {
  final int? id;
  final String username;
  final String password; // En una app real, esto debería ser un hash
  final String role; // Por ejemplo, 'admin', 'seller'
  final String status; // 'active' o 'blocked'

  User({
    this.id,
    required this.username,
    required this.password,
    this.role = 'vendedor', // Rol por defecto
    this.status = 'active', // Estado por defecto
  });

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'username': username, 'password': password, 'role': role};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'] ?? 'vendedor',
      status: map['status'] ?? 'active',
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, role: $role, status: $status)';
}
