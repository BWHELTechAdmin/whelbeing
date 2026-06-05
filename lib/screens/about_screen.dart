import 'package:flutter/material.dart';
import '../utils/size_config.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          children: [
            SizedBox(height: 2.0 * vh),
            // App logo / icon
            Container(
              padding: EdgeInsets.all(5.0 * vw),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC9A96E), Color(0xFF6B5220)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 12.0 * vw,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.0 * vh),
            const Text(
              'Whelbeing',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 0.5 * vh),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 2.8 * vh),
            // Mission statement
            Container(
              padding: EdgeInsets.all(5.0 * vw),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2520).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4.0 * vw),
              ),
              child: Column(
                children: [
                  const Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8DCC8),
                    ),
                  ),
                  SizedBox(height: 1.5 * vh),
                  Text(
                    'Whelbeing is dedicated to empowering women with tools '
                    'to understand and take control of their health. We '
                    'believe that knowledge, community, and self-awareness '
                    'are the foundations of wellbeing.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.8 * vh),
            // Features
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What We Offer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8DCC8),
                ),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            _buildFeatureCard(
              Icons.book,
              'Learn',
              'Expert-reviewed educational content on women\'s health topics',
            ),
            SizedBox(height: 1.0 * vh),
            _buildFeatureCard(
              Icons.people,
              'Connect',
              'Supportive community forums to share experiences and advice',
            ),
            SizedBox(height: 1.0 * vh),
            _buildFeatureCard(
              Icons.favorite,
              'Track',
              'Comprehensive health tracking including cycle, mood, and symptoms',
            ),
            SizedBox(height: 2.8 * vh),
            // Links
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Legal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8DCC8),
                ),
              ),
            ),
            SizedBox(height: 1.5 * vh),
            _buildLinkTile(context, 'Terms of Service', Icons.description_outlined),
            SizedBox(height: 1.0 * vh),
            _buildLinkTile(context, 'Privacy Policy', Icons.privacy_tip_outlined),
            SizedBox(height: 1.0 * vh),
            _buildLinkTile(context, 'Open Source Licenses', Icons.code),
            SizedBox(height: 3.8 * vh),
            Text(
              'Made with ♥ for women everywhere',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 0.5 * vh),
            Text(
              '© 2026 Whelbeing. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 2.8 * vh),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Container(
      padding: EdgeInsets.all(4.0 * vw),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3.0 * vw),
        border: Border.all(color: const Color(0xFF2A2520)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.5 * vw),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2520).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5 * vw),
            ),
            child: Icon(icon, color: const Color(0xFFE8DCC8), size: 5.5 * vw),
          ),
          SizedBox(width: 3.5 * vw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8DCC8),
                  ),
                ),
                SizedBox(height: 0.25 * vh),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, String title, IconData icon) {
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title will open in your browser'),
            backgroundColor: const Color(0xFFC9A96E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(3.5 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC9A96E), size: 5.0 * vw),
            SizedBox(width: 3.5 * vw),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE8DCC8),
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: const Color(0xFFC9A96E),
              size: 4.5 * vw,
            ),
          ],
        ),
      ),
    );
  }
}
