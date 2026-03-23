class User {
  final String id;
  final String email;
  final String? passwordHash;

  User({
    required this.id,
    required this.email,
    this.passwordHash,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['password_hash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
    };
  }
}
