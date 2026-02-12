class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.location,
    required this.content,
    required this.scope,
    required this.emotionIndex,
    required this.createdAt,
    required this.imagePaths,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  final String id;
  final String title;
  final String location;
  final String content;
  final String scope;
  final int emotionIndex;
  final DateTime createdAt;
  final List<String> imagePaths;
  final int likeCount;
  final int commentCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'content': content,
      'scope': scope,
      'emotionIndex': emotionIndex,
      'createdAt': createdAt.toIso8601String(),
      'imagePaths': imagePaths,
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      content: json['content'] as String? ?? '',
      scope: json['scope'] as String? ?? '전체공개',
      emotionIndex: json['emotionIndex'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      imagePaths:
          ((json['imagePaths'] as List?) ?? []).map((e) => '$e').toList(),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }
}
