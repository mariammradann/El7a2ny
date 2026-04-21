enum SponsorCategory { cars, insurance, medical }

class SponsorModel {
  final int id;
  final SponsorCategory category;
  final String title;
  final String rating;
  final String badgeLabel;
  final String description;
  final List<String> services;
  final String phone;
  final String branch;
  final bool isFeatured;

  const SponsorModel({
    required this.id,
    required this.category,
    required this.title,
    required this.rating,
    required this.badgeLabel,
    required this.description,
    required this.services,
    required this.phone,
    required this.branch,
    this.isFeatured = false,
  });

  factory SponsorModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = (json['category'] ?? '').toString().toLowerCase();
    final category = switch (rawCategory) {
      'car' || 'cars' => SponsorCategory.cars,
      'insurance' => SponsorCategory.insurance,
      'medical' || 'health' => SponsorCategory.medical,
      _ => SponsorCategory.cars,
    };
    return SponsorModel(
      id: json['id'] as int,
      category: category,
      title: json['title'] as String,
      rating: json['rating']?.toString() ?? '0.0',
      badgeLabel: json['badge_label'] as String,
      description: json['description'] as String,
      services: List<String>.from(json['services'] ?? []),
      phone: json['phone'] as String,
      branch: json['branch'] as String,
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': switch (category) {
        SponsorCategory.cars => 'cars',
        SponsorCategory.insurance => 'insurance',
        SponsorCategory.medical => 'medical',
      },
      'title': title,
      'rating': rating,
      'badge_label': badgeLabel,
      'description': description,
      'services': services,
      'phone': phone,
      'branch': branch,
      'is_featured': isFeatured,
    };
  }
}
