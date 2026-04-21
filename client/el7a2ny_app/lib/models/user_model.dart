class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'citizen', 'volunteer', 'admin'
  final String status; // 'active', 'pending', 'suspended'
  final List<String>? certifications;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.certifications,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'] ?? '',
        role: json['role'] ?? 'citizen',
        status: json['status'] ?? 'active',
        certifications: json['certifications'] != null ? List<String>.from(json['certifications']) : null,
        profileImageUrl: json['profile_image_url'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'certifications': certifications,
        'profile_image_url': profileImageUrl,
      };
}
