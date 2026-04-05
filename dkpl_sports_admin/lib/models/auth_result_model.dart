import 'staff_model.dart';

class AuthResult {
  final bool success;
  final String message;
  final StaffModel? user;
  const AuthResult({required this.success, required this.message, this.user});
}
