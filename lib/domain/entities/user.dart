// lib/domain/entities/user.dart
class User {
  final String id;
  final String username;
  final String email;
  final DateTime lastSeen;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.lastSeen,
  });
}

