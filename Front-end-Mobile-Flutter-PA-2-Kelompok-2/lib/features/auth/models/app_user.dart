// lib/features/auth/models/app_user.dart

class AppUser {
  final String id;
  final String email;
  final String role;
  final String companyId;
  final String status;
  final String name;
  final String phone;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.companyId,
    required this.status,
    required this.name,
    required this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['ID'] ?? json['id'] ?? '').toString(),
      email: (json['Email'] ?? json['email'] ?? '').toString(),
      role: (json['Role'] ?? json['role'] ?? '').toString(),
      companyId: (json['CompanyID'] ?? json['company_id'] ?? '').toString(),
      status: (json['Status'] ?? json['status'] ?? '').toString(),
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      phone: (json['Phone'] ?? json['phone'] ?? '').toString(),
    );
  }
}