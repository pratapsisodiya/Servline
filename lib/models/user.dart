import 'package:appwrite/models.dart' as appwrite;

/// User model with Appwrite serialization
class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final DateTime? createdAt;
  final bool isGuest;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.createdAt,
    this.isGuest = false,
  });

  /// Create User from Appwrite Account
  factory User.fromAppwriteUser(appwrite.User user) {
    final isGuest = user.email.isEmpty;
    return User(
      id: user.$id,
      email: user.email.isNotEmpty ? user.email : 'guest@servline.app',
      name: user.name.isNotEmpty
          ? user.name
          : (user.email.isNotEmpty
                ? user.email.split('@').first
                : 'Guest User'),
      phone: user.phone.isNotEmpty ? user.phone : null,
      createdAt: DateTime.tryParse(user.$createdAt),
      isGuest: isGuest,
    );
  }

  /// Create User from Appwrite Document
  factory User.fromDocument(appwrite.Document doc) {
    return User(
      id: doc.$id,
      email: doc.data['email'] ?? '',
      name: doc.data['name'] ?? '',
      phone: doc.data['phone'],
      createdAt: doc.data['createdAt'] != null
          ? DateTime.tryParse(doc.data['createdAt'])
          : null,
      isGuest: doc.data['isGuest'] ?? false,
    );
  }

  /// Create guest user
  factory User.guest() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return User(
      id: 'guest_$timestamp',
      email: 'guest_$timestamp@servline.local',
      name: 'Guest User',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
      'isGuest': isGuest,
    };
  }

  /// Copy with new values
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    DateTime? createdAt,
    bool? isGuest,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
