import 'package:flutter/material.dart';
import '../utils/size_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notification> _notifications = [
    _Notification(
      title: 'Period predicted in 2 days',
      body: 'Based on your cycle history, your next period is expected to start on February 12.',
      icon: Icons.calendar_today,
      color: const Color(0xFF8B6548),
      timeAgo: '30m ago',
      isRead: false,
    ),
    _Notification(
      title: 'Jamie L. replied to your post',
      body: '"I started doing 10 minutes of meditation every morning and it has been a game-changer..."',
      icon: Icons.chat_bubble_outline,
      color: const Color(0xFFC9A96E),
      timeAgo: '1h ago',
      isRead: false,
    ),
    _Notification(
      title: 'Don\'t forget to log today!',
      body: 'Keep your streak going — you\'re on day 28! Tap to log your daily symptoms.',
      icon: Icons.edit_note,
      color: const Color(0xFFC9A96E),
      timeAgo: '3h ago',
      isRead: false,
    ),
    _Notification(
      title: 'New article: Nutrition for Hormonal Balance',
      body: 'Learn about foods that support hormonal health. 7 min read.',
      icon: Icons.article_outlined,
      color: const Color(0xFFE8DCC8),
      timeAgo: '5h ago',
      isRead: true,
    ),
    _Notification(
      title: 'Water reminder',
      body: 'You\'ve logged 4 of 8 glasses today. Keep it up!',
      icon: Icons.water_drop,
      color: const Color(0xFF7EC8E3),
      timeAgo: '6h ago',
      isRead: true,
    ),
    _Notification(
      title: 'Weekly health digest',
      body: 'Your weekly summary is ready. You logged 6 out of 7 days and hit 3 health goals.',
      icon: Icons.summarize_outlined,
      color: const Color(0xFF6B5220),
      timeAgo: '1d ago',
      isRead: true,
    ),
    _Notification(
      title: 'Dr. Patel replied to your post',
      body: '"Box breathing is one of the simplest and most effective techniques..."',
      icon: Icons.chat_bubble_outline,
      color: const Color(0xFFC9A96E),
      timeAgo: '1d ago',
      isRead: true,
    ),
    _Notification(
      title: 'Fertile window starts tomorrow',
      body: 'Based on your cycle data, your fertile window is predicted to begin tomorrow.',
      icon: Icons.favorite_outline,
      color: const Color(0xFF8B6548),
      timeAgo: '2d ago',
      isRead: true,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFFE8DCC8),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 1.0 * SizeConfig.vh),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationTile(notification, index);
        },
      ),
    );
  }

  Widget _buildNotificationTile(_Notification notification, int index) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Dismissible(
      key: ValueKey(index),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 5.0 * vw),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) {
        setState(() => _notifications.removeAt(index));
      },
      child: GestureDetector(
        onTap: () {
          setState(() => notification.isRead = true);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.0 * vw, vertical: 1.5 * vh),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : const Color(0xFF1E1E1E).withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(2.5 * vw),
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 5.0 * vw,
                ),
              ),
              SizedBox(width: 3.0 * vw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: const Color(0xFFE8DCC8),
                            ),
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5 * vh),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                SizedBox(width: 2.0 * vw),
                Container(
                  width: 2.0 * vw,
                  height: 2.0 * vw,
                  margin: EdgeInsets.only(top: 0.5 * vh),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC9A96E),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Notification {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String timeAgo;
  bool isRead;

  _Notification({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.isRead,
  });
}
