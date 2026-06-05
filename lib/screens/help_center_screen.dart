import 'package:flutter/material.dart';
import '../widgets/gold_shimmer.dart';
import '../utils/size_config.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search-like header
            GoldShimmerContainer(
              padding: EdgeInsets.all(4.0 * vw),
              borderRadius: BorderRadius.circular(4.0 * vw),
              child: Column(
                children: [
                  const Text(
                    'How can we help?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.5 * vh),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.0 * vw),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6.0 * vw),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[400]),
                        SizedBox(width: 2.0 * vw),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for help...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.8 * vh),
            // Quick actions
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context,
                    'Email Support',
                    Icons.email_outlined,
                  ),
                ),
                SizedBox(width: 3.0 * vw),
                Expanded(
                  child: _buildContactCard(
                    context,
                    'Live Chat',
                    Icons.chat_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.8 * vh),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            _buildFaqItem(
              'How do I track my cycle?',
              'Go to the Track tab and tap the cycle tracker at the top. '
                  'You can log your period start and end dates, and the app will '
                  'learn your patterns over time to provide predictions.',
            ),
            _buildFaqItem(
              'How accurate are the cycle predictions?',
              'Predictions improve with more data. After 3 or more logged cycles, '
                  'predictions become quite accurate. Remember that stress, travel, '
                  'and lifestyle changes can affect your cycle.',
            ),
            _buildFaqItem(
              'Can I export my health data?',
              'Yes! Go to Profile > Settings and tap "Export Data". You\'ll '
                  'receive a file with all your logged health data that you can '
                  'share with your healthcare provider.',
            ),
            _buildFaqItem(
              'Is my data private?',
              'Absolutely. Your health data is encrypted and stored securely. '
                  'We never share your personal health information with third parties. '
                  'You can review our full privacy policy in Settings.',
            ),
            _buildFaqItem(
              'How do I join a community group?',
              'Navigate to the Connect tab and browse available Support Groups. '
                  'Tap on any group to see discussions and start participating. '
                  'You can also create your own posts.',
            ),
            _buildFaqItem(
              'How do I delete my account?',
              'Go to Profile > Privacy & Security > Delete Account. Please note '
                  'that this action is permanent and will remove all your data.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label is not yet available'),
            backgroundColor: const Color(0xFFC9A96E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(5.0 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3.0 * vw),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2520).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFE8DCC8), size: 6.0 * vw),
            ),
            SizedBox(height: 1.5 * vh),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DCC8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Container(
      margin: EdgeInsets.only(bottom: 1.0 * vh),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3.0 * vw),
        border: Border.all(color: const Color(0xFF2A2520)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 4.0 * vw, vertical: 0.5 * vh),
        childrenPadding: EdgeInsets.fromLTRB(4.0 * vw, 0, 4.0 * vw, 2.0 * vh),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: const Color(0xFFC9A96E),
        collapsedIconColor: const Color(0xFFC9A96E),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8DCC8),
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
