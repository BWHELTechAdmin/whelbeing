import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../utils/size_config.dart';
import 'sub_thread_screen.dart';

class ThreadDetailScreen extends StatefulWidget {
  final CommunityThread thread;

  const ThreadDetailScreen({super.key, required this.thread});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  String _sortBy = 'Top';

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  List<Reply> get _sortedReplies {
    final replies = List<Reply>.from(widget.thread.replies);
    switch (_sortBy) {
      case 'Top':
        replies.sort((a, b) => b.score.compareTo(a.score));
        break;
      case 'New':
        replies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Old':
        replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return replies;
  }

  void _submitReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.thread.replies.add(
        Reply(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          author: 'You',
          body: text,
          createdAt: DateTime.now(),
        ),
      );
      _replyController.clear();
      _replyFocus.unfocus();
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final thread = widget.thread;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          thread.group,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(4.0 * vw),
              children: [
                // --- Original Post ---
                _buildOriginalPost(thread),
                SizedBox(height: 2.4 * vh),
                // --- Sort bar ---
                _buildSortBar(),
                SizedBox(height: 1.0 * vh),
                // --- Replies ---
                if (_sortedReplies.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 3.8 * vh),
                    child: Center(
                      child: Text(
                        'No replies yet. Be the first!',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ..._sortedReplies.map((r) => _buildReplyCard(r)),
              ],
            ),
          ),
          // --- Reply input ---
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildOriginalPost(CommunityThread thread) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Container(
      padding: EdgeInsets.all(4.0 * vw),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2520).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3.0 * vw),
        border: Border.all(color: const Color(0xFF2A2520)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 4.5 * vw,
                backgroundColor: const Color(0xFFC9A96E),
                child: Text(
                  thread.author[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 2.5 * vw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFFE8DCC8),
                      ),
                    ),
                    Text(
                      thread.timeAgo,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.5 * vw, vertical: 0.5 * vh),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A96E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3.0 * vw),
                ),
                child: Text(
                  thread.group,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE8DCC8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.7 * vh),
          // Title
          Text(
            thread.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8DCC8),
            ),
          ),
          SizedBox(height: 1.0 * vh),
          // Body
          Text(
            thread.body,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          SizedBox(height: 1.7 * vh),
          // Vote + reply count row
          Row(
            children: [
              _buildVoteControls(
                score: thread.score,
                onUpvote: () => setState(() => thread.upvotes++),
                onDownvote: () => setState(() => thread.downvotes++),
              ),
              SizedBox(width: 5.0 * vw),
              Icon(Icons.chat_bubble_outline, size: 4.5 * vw, color: Colors.grey[400]),
              SizedBox(width: 1.0 * vw),
              Text(
                '${thread.replies.length} ${thread.replies.length == 1 ? 'reply' : 'replies'}',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Row(
      children: [
        Text(
          'Sort by:',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        SizedBox(width: 2.0 * vw),
        for (final option in ['Top', 'New', 'Old']) ...[
          GestureDetector(
            onTap: () => setState(() => _sortBy = option),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 3.0 * vw, vertical: 0.7 * vh),
              decoration: BoxDecoration(
                color: _sortBy == option
                    ? const Color(0xFFC9A96E)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4.0 * vw),
                border: Border.all(
                  color: const Color(0xFFC9A96E),
                  width: 1,
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _sortBy == option
                      ? Colors.white
                      : const Color(0xFFE8DCC8),
                ),
              ),
            ),
          ),
          SizedBox(width: 1.5 * vw),
        ],
      ],
    );
  }

  void _openSubThread(Reply reply) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubThreadScreen(
          parentReply: reply,
          groupName: widget.thread.group,
        ),
      ),
    );
  }

  Widget _buildReplyCard(Reply reply) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final replyCount = reply.totalReplyCount;
    return GestureDetector(
      onTap: () => _openSubThread(reply),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.2 * vh),
        padding: EdgeInsets.all(3.5 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(2.5 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 3.5 * vw,
                  backgroundColor: const Color(0xFF6B5220),
                  child: Text(
                    reply.author[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 2.0 * vw),
                Text(
                  reply.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFFE8DCC8),
                  ),
                ),
                SizedBox(width: 2.0 * vw),
                Text(
                  _timeAgo(reply.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            SizedBox(height: 1.2 * vh),
            Text(
              reply.body,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
                height: 1.4,
              ),
            ),
            SizedBox(height: 1.2 * vh),
            Row(
              children: [
                _buildVoteControls(
                  score: reply.score,
                  onUpvote: () => setState(() => reply.upvotes++),
                  onDownvote: () => setState(() => reply.downvotes++),
                ),
                SizedBox(width: 4.0 * vw),
                Icon(Icons.chat_bubble_outline,
                    size: 4.0 * vw, color: Colors.grey[400]),
                SizedBox(width: 1.0 * vw),
                Text(
                  '$replyCount',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 4.5 * vw, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteControls({
    required int score,
    required VoidCallback onUpvote,
    required VoidCallback onDownvote,
  }) {
    final vw = SizeConfig.vw;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onUpvote,
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 5.0 * vw,
            color: const Color(0xFFC9A96E),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.5 * vw),
          child: Text(
            '$score',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8DCC8),
            ),
          ),
        ),
        GestureDetector(
          onTap: onDownvote,
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 5.0 * vw,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyInput() {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Container(
      padding: EdgeInsets.only(
        left: 4.0 * vw,
        right: 2.0 * vw,
        top: 1.2 * vh,
        bottom: MediaQuery.of(context).padding.bottom + 1.2 * vh,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: const Border(
          top: BorderSide(color: Color(0xFF2A2520)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              focusNode: _replyFocus,
              decoration: InputDecoration(
                hintText: 'Write a reply…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0 * vw),
                  borderSide: const BorderSide(color: Color(0xFF2A2520)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0 * vw),
                  borderSide: const BorderSide(color: Color(0xFF2A2520)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0 * vw),
                  borderSide:
                      const BorderSide(color: Color(0xFFC9A96E), width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.0 * vw,
                  vertical: 1.2 * vh,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitReply(),
            ),
          ),
          SizedBox(width: 1.0 * vw),
          IconButton(
            onPressed: _submitReply,
            icon: const Icon(Icons.send_rounded),
            color: const Color(0xFFE8DCC8),
          ),
        ],
      ),
    );
  }
}
