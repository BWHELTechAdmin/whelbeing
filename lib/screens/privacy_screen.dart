import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../services/biometric_service.dart';
import '../utils/size_config.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _analyticsSharing = true;
  bool _crashReports = true;
  bool _isSendingPasswordReset = false;
  bool _isDeletingAccount = false;

  Future<void> _sendPasswordReset() async {
    final email = ref.read(currentUserProvider)?.email;
    if (email == null || email.isEmpty) {
      _showMessage(
        'We could not find an email address for this account.',
        isError: true,
      );
      return;
    }

    setState(() => _isSendingPasswordReset = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      _showMessage('Password reset link sent to your email.');
    } on EmailRequestCooldownException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, isError: true);
    } on AuthException {
      if (!mounted) return;
      _showMessage(
        'We could not send a password reset link right now. Please try again.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'We could not send a password reset link right now. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSendingPasswordReset = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFFC9A96E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;
    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'We could not delete your account. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  void _confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account, health records, and other associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: _isDeletingAccount
                ? null
                : () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFC9A96E)),
            ),
          ),
          TextButton(
            onPressed: _isDeletingAccount
                ? null
                : () {
                    Navigator.of(ctx).pop();
                    _deleteAccount();
                  },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
            _buildBiometricToggle(),
            _buildActionTile(
              'Change Password',
              'Update your account password',
              Icons.lock_outline,
              _isSendingPasswordReset ? null : _sendPasswordReset,
              isLoading: _isSendingPasswordReset,
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
              () => _showMessage(
                'Your data export will be emailed to you shortly',
              ),
            ),
            _buildActionTile(
              'Delete Account',
              'Permanently delete your account and data',
              Icons.delete_outline,
              _isDeletingAccount ? null : _confirmAccountDeletion,
              isDestructive: true,
              isLoading: _isDeletingAccount,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBiometricToggle() {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return ValueListenableBuilder<bool>(
      valueListenable: BiometricSettings.notifier,
      builder: (context, enabled, _) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 4.0 * vw,
            vertical: 0.5 * vh,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(3.0 * vw),
              border: Border.all(color: const Color(0xFF2A2520)),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.0 * vw,
                vertical: 0.25 * vh,
              ),
              secondary: Container(
                padding: EdgeInsets.all(2.0 * vw),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2520).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.0 * vw),
                ),
                child: Icon(
                  Icons.fingerprint,
                  color: const Color(0xFFE8DCC8),
                  size: 5.0 * vw,
                ),
              ),
              title: const Text(
                'Biometric Lock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8DCC8),
                ),
              ),
              subtitle: Text(
                'Require Face ID or fingerprint to open the app',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              value: enabled,
              activeThumbColor: const Color(0xFFC9A96E),
              onChanged: BiometricSettings.setEnabled,
            ),
          ),
        );
      },
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: 3.0 * vw,
            vertical: 0.25 * vh,
          ),
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
    VoidCallback? onTap, {
    bool isDestructive = false,
    bool isLoading = false,
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: 3.0 * vw,
            vertical: 0.25 * vh,
          ),
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
          trailing: isLoading
              ? SizedBox(
                  width: 4.0 * vw,
                  height: 4.0 * vw,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC9A96E),
                  ),
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  size: 4.0 * vw,
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.5)
                      : const Color(0xFFC9A96E),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
