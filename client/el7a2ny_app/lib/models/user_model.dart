import '../data/models/emergency_contact.dart';
class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role; // 'citizen', 'volunteer', 'admin'
  final String status; // 'active', 'pending', 'suspended'
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
  final bool isPlus;
  final String? planType; // 'monthly', 'yearly'
  final DateTime? subscriptionDate;
  final DateTime? renewalDate;
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
    this.isPlus = false,
    this.planType,
    this.subscriptionDate,
    this.renewalDate,
  });

  String get name => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        firstName: json['first_name'] ?? json['name']?.split(' ').first ?? '',
        lastName: json['last_name'] ?? json['name']?.split(' ').last ?? '',
        email: json['email'],
        phone: json['phone'] ?? '',
        role: json['role'] ?? 'citizen',
        status: json['status'] ?? 'active',
        nationalId: json['national_id'] ?? '',
        birthDate: json['birth_date'] ?? '',
        gender: json['gender'] ?? 'male',
        bloodType: json['blood_type'] ?? 'O+',
        hasVehicle: json['has_vehicle'] ?? false,
        volunteerEnabled: json['volunteer_enabled'] ?? false,
        skills: json['skills'],
        smartWatchModel: json['smart_watch_model'],
        sensorModel: json['sensor_model'],
        emergencyContacts: (json['emergency_contacts'] as List?)
                ?.map((e) => EmergencyContact.fromJson(e))
                .toList() ??
            [],
        certifications: json['certifications'] != null
            ? List<String>.from(json['certifications'])
            : null,
        profileImageUrl: json['profile_image_url'],
        isPlus: json['is_plus'] ?? false,
        planType: json['plan_type'],
        subscriptionDate: json['subscription_date'] != null ? DateTime.parse(json['subscription_date']) : null,
        renewalDate: json['renewal_date'] != null ? DateTime.parse(json['renewal_date']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'national_id': nationalId,
        'birth_date': birthDate,
        'gender': gender,
        'blood_type': bloodType,
        'has_vehicle': hasVehicle,
        'volunteer_enabled': volunteerEnabled,
        'skills': skills,
        'smart_watch_model': smartWatchModel,
        'sensor_model': sensorModel,
        'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
        'certifications': certifications,
        'profile_image_url': profileImageUrl,
        'is_plus': isPlus,
        'plan_type': planType,
        'subscription_date': subscriptionDate?.toIso8601String(),
        'renewal_date': renewalDate?.toIso8601String(),
      };
}
