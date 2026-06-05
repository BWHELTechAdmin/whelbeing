import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../utils/size_config.dart';
import '../widgets/gold_shimmer.dart';
import 'thread_detail_screen.dart';
import 'create_thread_screen.dart';
import 'group_detail_screen.dart';
import 'notifications_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final List<CommunityThread> _threads = _buildSampleThreads();

  static List<CommunityThread> _buildSampleThreads() {
    final now = DateTime.now();
    return [
      CommunityThread(
        id: '1',
        author: 'Sarah M.',
        title: 'Tips for managing stress?',
        body:
            'Looking for natural ways to reduce daily stress. I\'ve been feeling overwhelmed lately with work and family responsibilities. What techniques have worked for you?',
        group: 'Mindful Living',
        createdAt: now.subtract(const Duration(hours: 2)),
        upvotes: 34,
        replies: [
          Reply(
            id: '1a',
            author: 'Jamie L.',
            body:
                'I started doing 10 minutes of meditation every morning and it has been a game-changer. The Headspace app is great for beginners!',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
            upvotes: 18,
            replies: [
              Reply(
                id: '1a-1',
                author: 'Sarah M.',
                body: 'I\'ve been wanting to try Headspace! Do you use the free version or the subscription?',
                createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
                upvotes: 5,
              ),
              Reply(
                id: '1a-2',
                author: 'Jamie L.',
                body: 'I started with the free version and then upgraded. The free content is honestly enough to get started though!',
                createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
                upvotes: 8,
              ),
            ],
          ),
          Reply(
            id: '1b',
            author: 'Dr. Patel',
            body:
                'Box breathing is one of the simplest and most effective techniques: breathe in for 4 counts, hold for 4, exhale for 4, hold for 4. Repeat 4 times.',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
            upvotes: 25,
            replies: [
              Reply(
                id: '1b-1',
                author: 'Nina K.',
                body: 'This works amazingly well for me before bed. I fall asleep so much faster now!',
                createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
                upvotes: 10,
              ),
            ],
          ),
          Reply(
            id: '1c',
            author: 'Nina K.',
            body:
                'Going for a walk without my phone has helped me so much. Even just 15 minutes outside makes a huge difference.',
            createdAt: now.subtract(const Duration(hours: 1)),
            upvotes: 12,
          ),
        ],
      ),
      CommunityThread(
        id: '2',
        author: 'Emily R.',
        title: 'Healthy meal prep ideas',
        body:
            'What are your go-to meal prep recipes? I\'m trying to eat healthier but I struggle with time during the week. Would love some quick, nutritious recipes!',
        group: 'Fitness Together',
        createdAt: now.subtract(const Duration(hours: 5)),
        upvotes: 52,
        replies: [
          Reply(
            id: '2a',
            author: 'Chef Marco',
            body:
                'Overnight oats are the easiest breakfast prep. Just mix oats, yogurt, milk, and your favourite toppings the night before. Done in 2 minutes!',
            createdAt: now.subtract(const Duration(hours: 4, minutes: 30)),
            upvotes: 30,
            replies: [
              Reply(
                id: '2a-1',
                author: 'Emily R.',
                body: 'What ratio of oats to yogurt do you use? Mine always come out too thick.',
                createdAt: now.subtract(const Duration(hours: 4)),
                upvotes: 7,
              ),
              Reply(
                id: '2a-2',
                author: 'Chef Marco',
                body: 'I do 1/2 cup oats, 1/4 cup yogurt, and 1/2 cup milk. You can always add more milk in the morning if it\'s too thick!',
                createdAt: now.subtract(const Duration(hours: 3, minutes: 45)),
                upvotes: 15,
              ),
            ],
          ),
          Reply(
            id: '2b',
            author: 'Tanya W.',
            body:
                'Sheet-pan dinners are my secret weapon. Throw chicken, veggies, and seasoning on a tray, bake for 25 min, and you\'ve got 4 meals.',
            createdAt: now.subtract(const Duration(hours: 4)),
            upvotes: 22,
          ),
        ],
      ),
      CommunityThread(
        id: '3',
        author: 'Lily T.',
        title: 'First trimester exhaustion – is this normal?',
        body:
            'I\'m 8 weeks pregnant and I have never been this tired in my life. I can barely keep my eyes open past 7pm. Anyone else experience this?',
        group: 'New Mothers',
        createdAt: now.subtract(const Duration(hours: 8)),
        upvotes: 41,
        replies: [
          Reply(
            id: '3a',
            author: 'Mama Bear',
            body:
                'Totally normal! Your body is building a placenta which takes a huge amount of energy. It usually gets better in the second trimester. Hang in there!',
            createdAt: now.subtract(const Duration(hours: 7)),
            upvotes: 35,
            replies: [
              Reply(
                id: '3a-1',
                author: 'Lily T.',
                body: 'Thank you so much, that\'s really reassuring! When did it start getting better for you?',
                createdAt: now.subtract(const Duration(hours: 6, minutes: 45)),
                upvotes: 4,
              ),
              Reply(
                id: '3a-2',
                author: 'Mama Bear',
                body: 'Around week 14 I suddenly felt like a new person. The energy boost was incredible!',
                createdAt: now.subtract(const Duration(hours: 6, minutes: 30)),
                upvotes: 12,
              ),
              Reply(
                id: '3a-3',
                author: 'Rachel D.',
                body: 'Same here – second trimester was like a whole different pregnancy. You\'ve got this! 💪',
                createdAt: now.subtract(const Duration(hours: 6)),
                upvotes: 9,
              ),
            ],
          ),
          Reply(
            id: '3b',
            author: 'Rachel D.',
            body:
                'I slept 12 hours a day during my first trimester. Give yourself grace – your body is doing incredible things right now.',
            createdAt: now.subtract(const Duration(hours: 6, minutes: 30)),
            upvotes: 28,
          ),
          Reply(
            id: '3c',
            author: 'Dr. Chen',
            body:
                'Make sure your iron levels are good – low iron can make the fatigue even worse. Ask your OB to check at your next visit.',
            createdAt: now.subtract(const Duration(hours: 6)),
            upvotes: 40,
          ),
        ],
      ),
    ];
  }

  void _openThread(CommunityThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThreadDetailScreen(thread: thread),
      ),
    );
  }

  Future<void> _createThread() async {
    final result = await Navigator.of(context).push<CommunityThread>(
      MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
    );
    if (result != null) {
      setState(() => _threads.insert(0, result));
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 2.0 * vh),
            _buildCommunityStats(),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Support Groups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            _buildGroupCard(
              context,
              'New Mothers',
              '2.4k members',
              'Support for postpartum wellness',
              Icons.child_care,
            ),
            SizedBox(height: 1.5 * vh),
            _buildGroupCard(
              context,
              'Mindful Living',
              '5.1k members',
              'Daily mindfulness and meditation',
              Icons.self_improvement,
            ),
            SizedBox(height: 1.5 * vh),
            _buildGroupCard(
              context,
              'Fitness Together',
              '3.8k members',
              'Workout motivation and tips',
              Icons.directions_run,
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Recent Discussions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            ..._threads.map((thread) => Padding(
                  padding: EdgeInsets.only(bottom: 1.5 * vh),
                  child: _buildDiscussionCard(thread),
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

  Widget _buildCommunityStats() {
    final vw = SizeConfig.vw;
    final vh = SizeConfig.vh;
    return GoldShimmerContainer(
      borderRadius: BorderRadius.circular(4.0 * vw),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('12.5k', 'Members'),
          Container(
            height: 4.7 * vh,
            width: 1,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          _buildStatItem('240', 'Groups'),
          Container(
            height: 4.7 * vh,
            width: 1,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          _buildStatItem('1.2k', 'Active Today'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    String name,
    String members,
    String description,
    IconData icon,
  ) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(
              groupName: name,
              memberCount: members,
              description: description,
              icon: icon,
              threads: _threads,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(
            color: const Color(0xFF2A2520),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.0 * vw),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.0 * vw),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3.0 * vw),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFE8DCC8),
                  size: 6.0 * vw,
                ),
              ),
              SizedBox(width: 4.0 * vw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8DCC8),
                      ),
                    ),
                    SizedBox(height: 0.5 * vh),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 0.5 * vh),
                    Text(
                      members,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC9A96E),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFFC9A96E),
                size: 4.0 * vw,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionCard(CommunityThread thread) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: () => _openThread(thread),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.author,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE8DCC8),
                          ),
                        ),
                        Text(
                          thread.group,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
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
