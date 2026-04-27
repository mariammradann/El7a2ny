import 'dart:convert';
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة للتعامل مع تقسيم الاسم لو دجانجو بعت "name" فقط
    String full_name = json['name'] ?? '';
    List<String> nameParts = full_name.split(' ');

    // Handle potential stringified JSON for emergency_contacts
    List<dynamic> emergencyList = [];
    if (json['emergency_contacts'] is String) {
      try {
        final decoded = jsonDecode(json['emergency_contacts']);
        if (decoded is List) emergencyList = decoded;
      } catch (_) {}
    } else if (json['emergency_contacts'] is List) {
      emergencyList = json['emergency_contacts'];
    }

    return UserModel(
      // 1. قراءة الـ ID كـ String والتعامل مع مسمى user_id
      id: (json['user_id'] ?? json['id'] ?? '').toString(), 
      
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
      emergencyContacts: emergencyList.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList(),
      certifications: json['certifications'] != null ? List<String>.from(json['certifications']) : null,
      profileImageUrl: json['profile_image_url'],
      isPlus: json['is_plus'] ?? false,
      planType: json['plan_type'],
      subscriptionDate: json['subscription_date'] != null ? DateTime.parse(json['subscription_date']) : null,
      renewalDate: json['renewal_date'] != null ? DateTime.parse(json['renewal_date']) : null,
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
        'has_vehicle': hasVehicle,
        'volunteer_enabled': volunteerEnabled,
        'skills': skills,
        'smart_watch_model': smartWatchModel,
        'sensor_model': sensorModel,
        'certifications': certifications,
        'profile_image_url': profileImageUrl,
        'is_plus': isPlus,
        'plan_type': planType,
        'subscription_date': subscriptionDate?.toIso8601String(),
        'renewal_date': renewalDate?.toIso8601String(),
      };

}