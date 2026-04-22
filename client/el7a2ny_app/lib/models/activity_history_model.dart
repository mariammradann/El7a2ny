class ActivityHistoryModel {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // 'emergency', 'volunteer', 'account'

  ActivityHistoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });

  factory ActivityHistoryModel.fromJson(Map<String, dynamic> json) => ActivityHistoryModel(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    type: json['type'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'type': type,
  };
}
