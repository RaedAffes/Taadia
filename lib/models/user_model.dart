class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String promotedBy;
  final String authProvider;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.promotedBy = '',
    this.authProvider = 'email',
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'user',
      promotedBy: data['promotedBy'] ?? '',
      authProvider: data['authProvider'] ?? 'email',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'promotedBy': promotedBy,
      'authProvider': authProvider,
      'createdAt': DateTime.now(),
      'lastLoginAt': DateTime.now(),
    };
  }
}
