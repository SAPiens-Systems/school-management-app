class AdminUser {
  final String uid;
  final String name;
  final String email;
  final String schoolId;
  final String role;
  final String status;
  final DateTime createdAt;

  AdminUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'schoolId': schoolId,
      'role': role,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      schoolId: map['schoolId'] ?? '',
      role: map['role'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
