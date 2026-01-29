class WorkPackageActivity {
  final String id;
  final String authorName;
  /// Yazar kullanıcı ID (avatar için; _links.user.href'ten).
  final String? authorId;
  final DateTime createdAt;
  final String? comment;
  final bool isComment;

  const WorkPackageActivity({
    required this.id,
    required this.authorName,
    this.authorId,
    required this.createdAt,
    required this.isComment,
    this.comment,
  });

  static String? _idFromHref(dynamic href) {
    if (href == null) return null;
    final s = href.toString();
    if (s.contains('/users/')) return s.split('/users/').last.split('/').first.trim();
    return null;
  }

  factory WorkPackageActivity.fromJson(Map json) {
    final links = json['_links'] as Map<String, dynamic>? ?? const {};
    final author = links['user'] as Map<String, dynamic>?;
    final authorHref = author?['href']?.toString();
    final comment = json['comment'] as Map<String, dynamic>?;
    final created = json['createdAt'] as String?;

    return WorkPackageActivity(
      id: (json['id'] ?? '').toString(),
      authorName: (author?['title'] ?? '').toString(),
      authorId: _idFromHref(authorHref),
      createdAt: created != null ? DateTime.tryParse(created) ?? DateTime.now() : DateTime.now(),
      isComment: (json['_type']?.toString() ?? '').contains('Comment'),
      comment: comment == null ? null : (comment['raw'] ?? comment['html'] ?? '').toString(),
    );
  }
}

