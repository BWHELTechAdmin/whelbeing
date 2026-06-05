class Reply {
  final String id;
  final String author;
  final String body;
  final DateTime createdAt;
  final List<Reply> replies;
  int upvotes;
  int downvotes;

  Reply({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    List<Reply>? replies,
    this.upvotes = 0,
    this.downvotes = 0,
  }) : replies = replies ?? [];

  int get score => upvotes - downvotes;

  int get totalReplyCount {
    int count = replies.length;
    for (final r in replies) {
      count += r.totalReplyCount;
    }
    return count;
  }
}

class CommunityThread {
  final String id;
  final String author;
  final String title;
  final String body;
  final String group;
  final DateTime createdAt;
  final List<Reply> replies;
  int upvotes;
  int downvotes;

  CommunityThread({
    required this.id,
    required this.author,
    required this.title,
    required this.body,
    required this.group,
    required this.createdAt,
    List<Reply>? replies,
    this.upvotes = 0,
    this.downvotes = 0,
  }) : replies = replies ?? [];

  int get score => upvotes - downvotes;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
