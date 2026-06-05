import 'package:flutter/material.dart';
import '../utils/size_config.dart';

class ProfileSubpageScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ProfileSubpageScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0 * vw),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5.0 * vw),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 12.0 * vw,
                  color: const Color(0xFFE8DCC8),
                ),
              ),
              SizedBox(height: 2.8 * vh),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8DCC8),
                ),
              ),
              SizedBox(height: 1.0 * vh),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.8 * vh),
              Container(
                padding: EdgeInsets.all(4.0 * vw),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3.0 * vw),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.construction_outlined,
                      color: Color(0xFFC9A96E),
                    ),
                    SizedBox(width: 3.0 * vw),
                    Text(
                      'Coming soon',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
