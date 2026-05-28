enum SponsorCategory { cars, insurance, medical }

class SponsorModel {
  final String sponsorId;
  final SponsorCategory category;
  final String name;
  final String phone;
  final String contactEmail;
  final String sponsorshipLevel;
  final String status;
  final String? website;

  const SponsorModel({
    required this.sponsorId,
    required this.category,
    required this.name,
    required this.phone,
    required this.contactEmail,
    required this.sponsorshipLevel,
    required this.status,
    this.website,
  });

  factory SponsorModel.fromJson(Map<String, dynamic> json) {
    // Map company_type from backend to SponsorCategory enum
    final rawType = (json['company_type'] ?? '').toString().toLowerCase();
    final category = switch (rawType) {
      'cars' || 'car' => SponsorCategory.cars,
      'insurance' => SponsorCategory.insurance,
      'medical' || 'health' => SponsorCategory.medical,
      _ => SponsorCategory.cars,
    };

    return SponsorModel(
      sponsorId: json['sponsor_id']?.toString() ?? '',
      category: category,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      contactEmail: json['contact_email']?.toString() ?? '',
      sponsorshipLevel: json['sponsorship_level']?.toString() ?? 'silver',
      status: json['status']?.toString() ?? 'active',
      website: json['website']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sponsor_id': sponsorId,
      'company_type': switch (category) {
        SponsorCategory.cars => 'cars',
        SponsorCategory.insurance => 'insurance',
        SponsorCategory.medical => 'medical',
      },
      'name': name,
      'phone': phone,
      'contact_email': contactEmail,
      'sponsorship_level': sponsorshipLevel,
      'status': status,
      'website': website,
    };
  }
}

