class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      relationship: (json['relationship'] ?? '').toString(),
      );
}
