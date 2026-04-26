enum HelpCategory {
  food,
  clothing,
  financial,
  medical,
  education,
  other;

  String get categoryIcon {
    switch (this) {
      case HelpCategory.food:
        return '🍽️';
      case HelpCategory.clothing:
        return '👕';
      case HelpCategory.financial:
        return '💰';
      case HelpCategory.medical:
        return '🏥';
      case HelpCategory.education:
        return '📚';
      case HelpCategory.other:
        return '📦';
    }
  }
}

class HelpInitiative {
  final int id;
  final String title;
  final String description;
  final String authorName;
  final DateTime createdAt;
  final String authorRole;
  final HelpCategory category;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final List<String> contactInfo;
  final bool isActive;
  final int participantsCount;

  HelpInitiative({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    required this.createdAt,
    required this.authorRole,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.contactInfo = const [],
    this.isActive = true,
    this.participantsCount = 0,
  });

  factory HelpInitiative.fromJson(Map<String, dynamic> json) => HelpInitiative(
        id: json['id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        authorName: json['author_name'] ?? 'User',
        createdAt: DateTime.parse(json['created_at']),
        authorRole: json['author_role'] ?? 'citizen',
        category: HelpCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => HelpCategory.other,
        ),
        location: json['location'] ?? '',
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        imageUrl: json['image_url'],
        contactInfo: List<String>.from(json['contact_info'] ?? []),
        isActive: json['is_active'] ?? true,
        participantsCount: json['participants_count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'author_name': authorName,
        'created_at': createdAt.toIso8601String(),
        'author_role': authorRole,
        'category': category.name,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'contact_info': contactInfo,
        'is_active': isActive,
        'participants_count': participantsCount,
      };

  String get categoryIcon {
    switch (category) {
      case HelpCategory.food:
        return '🍽️';
      case HelpCategory.clothing:
        return '👕';
      case HelpCategory.financial:
        return '💰';
      case HelpCategory.medical:
        return '🏥';
      case HelpCategory.education:
        return '📚';
      case HelpCategory.other:
        return '🤝';
    }
  }
}