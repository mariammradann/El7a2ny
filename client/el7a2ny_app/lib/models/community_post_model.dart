class CommunityPost {
  final int id;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final String authorRole; // 'system', 'volunteer', 'citizen'
  final bool hasAction;
  final String? actionLabel;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.authorRole,
    this.hasAction = false,
    this.actionLabel,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'],
        authorName: json['author_name'] ?? 'User',
        content: json['content'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
        authorRole: json['author_role'] ?? 'citizen',
        hasAction: json['has_action'] ?? false,
        actionLabel: json['action_label'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'author_role': authorRole,
        'has_action': hasAction,
        'action_label': actionLabel,
      };
}
