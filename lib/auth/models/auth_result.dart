class AuthResult {
  final bool success;
  final String? error;
  final String? uid;
  final String? role;

  AuthResult({required this.success, this.error, this.uid, this.role});
}
