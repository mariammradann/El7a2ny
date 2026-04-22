import '../data/models/emergency_contact.dart';

class UserModel {
  final String id; // تم التغيير من int لـ String لأن دجانجو بيبعت UUID
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role; 
  final String status; 
  final String nationalId;
  final String birthDate;
  final String gender;
  final String bloodType;
  final bool hasVehicle;
  final bool volunteerEnabled;
  final String? skills;
  final String? smartWatchModel;
  final String? sensorModel;
  final List<EmergencyContact> emergencyContacts;
  final List<String>? certifications;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.nationalId,
    required this.birthDate,
    required this.gender,
    required this.bloodType,
    this.hasVehicle = false,
    this.volunteerEnabled = false,
    this.skills,
    this.smartWatchModel,
    this.sensorModel,
    this.emergencyContacts = const [],
    this.certifications,
    this.profileImageUrl,
  });

  String get name => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة للتعامل مع تقسيم الاسم لو دجانجو بعت "name" فقط
    String full_name = json['name'] ?? '';
    List<String> nameParts = full_name.split(' ');

    return UserModel(
      // 1. قراءة الـ ID كـ String والتعامل مع مسمى user_id
      id: (json['user_id'] ?? json['id']).toString(), 
      
      // 2. معالجة الأسماء
      firstName: json['first_name'] ?? (nameParts.isNotEmpty ? nameParts.first : ''),
      lastName: json['last_name'] ?? (nameParts.length > 1 ? nameParts.last : ''),
      
      email: json['email'] ?? '',
      phone: json['phone_number'] ?? json['phone'] ?? '',
      role: json['user_type'] ?? json['role'] ?? 'citizen',
      status: json['status'] ?? 'active',
      nationalId: json['national_id'] ?? '',
      birthDate: json['date_of_birth']?.toString() ?? json['birth_date']?.toString() ?? '',
      gender: json['gender'] ?? 'male',
      bloodType: json['blood_type'] ?? 'O+',
      hasVehicle: json['has_vehicle'] ?? false,
      volunteerEnabled: json['volunteer_enabled'] ?? false,
      skills: json['skills'],
      smartWatchModel: json['smart_watch_model'],
      sensorModel: json['sensor_model'],
      emergencyContacts: (json['emergency_contacts'] as List?)
          ?.map((e) => EmergencyContact.fromJson(e))
          .toList() ?? [],
      certifications: json['certifications'] != null ? List<String>.from(json['certifications']) : null,
      profileImageUrl: json['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'name': '$firstName $lastName',
        'email': email,
        'phone_number': phone,
        'user_type': role,
        'status': status,
        'national_id': nationalId,
        'date_of_birth': birthDate,
        'gender': gender,
        'blood_type': bloodType,
        'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
      };
}