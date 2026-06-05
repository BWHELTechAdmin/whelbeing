import 'package:flutter/material.dart';
import '../utils/size_config.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _biometricLock = false;
  bool _hideProfile = false;
  bool _analyticsSharing = true;
  bool _crashReports = true;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy & Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 1.0 * SizeConfig.vh),
        children: [
          _buildSection('Security', [
            _buildToggle(
              'Biometric Lock',
              'Require Face ID or fingerprint to open the app',
              Icons.fingerprint,
              _biometricLock,
              (v) => setState(() => _biometricLock = v),
            ),
            _buildActionTile(
              'Change Password',
              'Update your account password',
              Icons.lock_outline,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset link sent to your email'),
                    backgroundColor: Color(0xFFC9A96E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ]),
          _buildSection('Privacy', [
            _buildToggle(
              'Hide Profile from Community',
              'Your posts will appear as Anonymous',
              Icons.visibility_off_outlined,
              _hideProfile,
              (v) => setState(() => _hideProfile = v),
            ),
            _buildActionTile(
              'Blocked Users',
              'Manage your blocked user list',
              Icons.block,
              () {},
            ),
          ]),
          _buildSection('Data', [
            _buildToggle(
              'Usage Analytics',
              'Help us improve by sharing anonymous usage data',
              Icons.analytics_outlined,
              _analyticsSharing,
              (v) => setState(() => _analyticsSharing = v),
            ),
            _buildToggle(
              'Crash Reports',
              'Automatically send crash reports',
              Icons.bug_report_outlined,
              _crashReports,
              (v) => setState(() => _crashReports = v),
            ),
            _buildActionTile(
              'Download My Data',
              'Get a copy of all your personal data',
              Icons.download_outlined,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your data export will be emailed to you shortly'),
                    backgroundColor: Color(0xFFC9A96E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildActionTile(
              'Delete Account',
              'Permanently delete your account and data',
              Icons.delete_outline,
              () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text(
                      'This will permanently delete your account and all associated data. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFFC9A96E)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              isDestructive: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.0 * vw, 2.4 * vh, 4.0 * vw, 1.0 * vh),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8DCC8),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0 * vw, vertical: 0.5 * vh),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 3.0 * vw, vertical: 0.25 * vh),
          secondary: Container(
            padding: EdgeInsets.all(2.0 * vw),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2520).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.0 * vw),
            ),
            child: Icon(icon, color: const Color(0xFFE8DCC8), size: 5.0 * vw),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE8DCC8),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          value: value,
          activeThumbColor: const Color(0xFFC9A96E),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0 * vw, vertical: 0.5 * vh),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.3)
                : const Color(0xFF2A2520),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 3.0 * vw, vertical: 0.25 * vh),
          leading: Container(
            padding: EdgeInsets.all(2.0 * vw),
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.1)
                  : const Color(0xFF2A2520).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.0 * vw),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFFE8DCC8),
              size: 5.0 * vw,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : const Color(0xFFE8DCC8),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 4.0 * vw,
            color: isDestructive ? Colors.red.withValues(alpha: 0.5) : const Color(0xFFC9A96E),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
