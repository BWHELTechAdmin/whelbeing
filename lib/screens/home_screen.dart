import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_conversation.dart';
import '../providers/ai_conversation_provider.dart';
import '../providers/user_provider.dart';
import '../services/ai_service.dart';
import '../widgets/gold_shimmer.dart';
import '../utils/size_config.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final firstName = ref
            .watch(currentUserModelProvider)
            .valueOrNull
            ?.displayFirstName ??
        'there';
    final avatarUrl = ref.watch(avatarUrlProvider).valueOrNull;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(4.0 * vw, 0, 4.0 * vw, 12.0 * vh),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.0 * vh),
              // Welcome hero section
              GoldShimmerContainer(
                padding: EdgeInsets.all(5.0 * vw),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              SizedBox(height: 0.3 * vh),
                              Text(
                                firstName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 4.0 * vw),
                        Semantics(
                          label: 'Open profile',
                          button: true,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 14.0 * vw,
                              height: 14.0 * vw,
                              padding: EdgeInsets.all(0.65 * vw),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC9A96E),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFF1E1E1E),
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 7.0 * vw,
                                        color: const Color(0xFFE8DCC8),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.5 * vh),
                    Text(
                      'Your wellness journey continues. Here\'s your overview for today.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 1.4 * vh),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.settings_outlined, size: 4.0 * vw),
                      label: const Text('Manage Profile & Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC9A96E),
                        side: const BorderSide(color: Color(0xFF3D2E14)),
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.0 * vw,
                          vertical: 1.0 * vh,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.8 * vh),

              // AI Prompt Grid
              Row(
                children: [
                  Expanded(
                    child: _buildAiCard(
                      context: context,
                      mode: AiMode.symptomNavigator,
                      subtitle: 'Describe how you feel — get structured next steps',
                    ),
                  ),
                  SizedBox(width: 3.0 * vw),
                  Expanded(
                    child: _buildAiCard(
                      context: context,
                      mode: AiMode.appointmentPrep,
                      subtitle: 'Walk into every visit confident and prepared',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5 * vh),
              Row(
                children: [
                  Expanded(
                    child: _buildAiCard(
                      context: context,
                      mode: AiMode.labInterpreter,
                      subtitle: 'Upload results — AI explains what they mean',
                    ),
                  ),
                  SizedBox(width: 3.0 * vw),
                  Expanded(
                    child: _buildAiCard(
                      context: context,
                      mode: AiMode.careGap,
                      subtitle: 'Find missing screenings and preventive gaps',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.8 * vh),

              // Recent AI Activity
              const Text(
                'RECENT AI ACTIVITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B5220),
                  letterSpacing: 2.2,
                ),
              ),
              SizedBox(height: 1.5 * vh),
              _buildAiActivitySection(ref, context),
              SizedBox(height: 2.8 * vh),
            ],
          ),
      ),
    );
  }

  Widget _buildAiCard({
    required BuildContext context,
    required AiMode mode,
    required String subtitle,
  }) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiChatScreen(mode: mode),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(4.5 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF161410),
          borderRadius: BorderRadius.circular(4.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mode.emoji, style: const TextStyle(fontSize: 32)),
            SizedBox(height: 2.0 * vh),
            Text(
              mode.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DCC8),
                height: 1.2,
              ),
            ),
            SizedBox(height: 0.7 * vh),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent AI Activity section ──────────────────────────────────────────────

  Widget _buildAiActivitySection(WidgetRef ref, BuildContext context) {
    final state = ref.watch(aiConversationsProvider);
    return state.when(
      loading: () => _buildActivityLoading(),
      error: (err, _) => _buildActivityError(ref),
      data: (data) {
        if (data.conversations.isEmpty) {
          return _buildActivityEmpty();
        }
        final vh = SizeConfig.vh;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...data.conversations.map(
              (c) => _buildAiActivityItem(conversation: c, context: context),
            ),
            if (data.hasMore)
              Padding(
                padding: EdgeInsets.only(top: 0.4 * vh),
                child: TextButton(
                  onPressed: () =>
                      ref.read(aiConversationsProvider.notifier).loadMore(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.2 * vh),
                    foregroundColor: const Color(0xFFC9A96E),
                  ),
                  child: const Text(
                    'Load more',
                    style: TextStyle(fontSize: 13, letterSpacing: 0.4),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActivityLoading() {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: EdgeInsets.only(bottom: 1.2 * vh),
          height: 6.5 * vh,
          decoration: BoxDecoration(
            color: const Color(0xFF161410),
            borderRadius: BorderRadius.circular(3.0 * vw),
            border: Border.all(color: const Color(0xFF2A2520)),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityEmpty() {
    final vh = SizeConfig.vh;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0 * vh),
      child: Text(
        'No AI activity yet — start a conversation above.',
        style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
      ),
    );
  }

  Widget _buildActivityError(WidgetRef ref) {
    final vh = SizeConfig.vh;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5 * vh),
      child: Row(
        children: [
          Text(
            'Could not load activity.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.invalidate(aiConversationsProvider),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFC9A96E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiActivityItem({
    required AiConversation conversation,
    required BuildContext context,
  }) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final type = conversation.aiMode.title.toUpperCase();
    final date = _formatDate(conversation.lastMessageAt);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiChatScreen(
            mode: conversation.aiMode,
            existingConversation: conversation,
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.2 * vh),
        padding: EdgeInsets.symmetric(horizontal: 4.0 * vw, vertical: 1.7 * vh),
        decoration: BoxDecoration(
          color: const Color(0xFF161410),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B6548),
                          letterSpacing: 1.4,
                        ),
                      ),
                      SizedBox(width: 1.5 * vw),
                      Text(
                        '· $date',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.6 * vh),
                  Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE8DCC8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: const Color(0xFF6B5220),
              size: 4.5 * vw,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
