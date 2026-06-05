import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../utils/size_config.dart';
import '../widgets/gold_shimmer.dart';
import 'thread_detail_screen.dart';
import 'create_thread_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupName;
  final String memberCount;
  final String description;
  final IconData icon;
  final List<CommunityThread> threads;

  const GroupDetailScreen({
    super.key,
    required this.groupName,
    required this.memberCount,
    required this.description,
    required this.icon,
    required this.threads,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late List<CommunityThread> _filteredThreads;

  @override
  void initState() {
    super.initState();
    _filteredThreads = widget.threads
        .where((t) => t.group == widget.groupName)
        .toList();
  }

  Future<void> _createThread() async {
    final result = await Navigator.of(context).push<CommunityThread>(
      MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
    );
    if (result != null) {
      setState(() => _filteredThreads.insert(0, result));
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoldShimmerContainer(
              borderRadius: BorderRadius.circular(4.0 * vw),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 9.0 * vw),
                  SizedBox(width: 4.0 * vw),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 1.0 * vh),
                        Text(
                          widget.memberCount,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Discussions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 2.0 * vh),
            if (_filteredThreads.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.8 * vh),
                  child: Column(
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 12.0 * vw,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 2.0 * vh),
                      Text(
                        'No discussions yet. Start one!',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredThreads.map((thread) => Padding(
                    padding: EdgeInsets.only(bottom: 1.5 * vh),
                    child: _buildThreadCard(thread),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createThread,
        backgroundColor: const Color(0xFFC9A96E),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildThreadCard(CommunityThread thread) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ThreadDetailScreen(thread: thread),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.0 * vw),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 4.0 * vw,
                    backgroundColor: const Color(0xFFC9A96E),
                    child: Text(
                      thread.author[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.0 * vw),
                  Expanded(
                    child: Text(
                      thread.author,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE8DCC8),
                      ),
                    ),
                  ),
                  Text(
                    thread.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5 * vh),
              Text(
                thread.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8DCC8),
                ),
              ),
              SizedBox(height: 0.7 * vh),
              Text(
                thread.body,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.5 * vh),
              Row(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 4.0 * vw,
                    color: Colors.grey[400],
                  ),
                  SizedBox(width: 0.5 * vw),
                  Text(
                    '${thread.score}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(width: 4.0 * vw),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 4.0 * vw,
                    color: Colors.grey[400],
                  ),
                  SizedBox(width: 1.0 * vw),
                  Text(
                    '${thread.replies.length} ${thread.replies.length == 1 ? 'reply' : 'replies'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
