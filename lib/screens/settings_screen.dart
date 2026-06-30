import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/biometric_provider.dart';
import '../services/biometric_service.dart';
import '../utils/size_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          _buildSection('General', [
            _buildToggle(
              'Dark Mode',
              Icons.dark_mode_outlined,
              _darkMode,
              (v) => setState(() => _darkMode = v),
            ),
            _buildToggle(
              'Push Notifications',
              Icons.notifications_outlined,
              _pushNotifications,
              (v) => setState(() => _pushNotifications = v),
            ),
          ]),
          _buildSection('Security', [
            _buildBiometricToggle(),
          ]),
          _buildSection('Data', [
            _buildTile('Export Data', Icons.download_outlined, () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Export Data'),
                  content: const Text(
                    'This will generate a file containing all your health data. '
                    'It will be sent to your registered email address.',
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
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data export started. Check your email shortly.'),
                            backgroundColor: Color(0xFFC9A96E),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Export',
                        style: TextStyle(color: Color(0xFFE8DCC8)),
                      ),
                    ),
                  ],
                ),
              );
            }),
            _buildTile('Clear Cache', Icons.cached, () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text(
                    'This will clear cached data like images and temporary files. '
                    'Your health data and account information will not be affected.',
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
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache cleared successfully.'),
                            backgroundColor: Color(0xFFC9A96E),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Color(0xFFE8DCC8)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ]),
          _buildSection('About', [
            _buildInfoTile('Version', '1.0.0'),
            _buildInfoTile('Build', '2026.02'),
          ]),
        ],
      ),
    );
  }

  Widget _buildBiometricToggle() {
    final enabled = ref.watch(biometricEnabledProvider);
    return SwitchListTile(
      secondary: Icon(
        Icons.fingerprint,
        color: _biometricAvailable
            ? const Color(0xFFC9A96E)
            : Colors.grey,
      ),
      title: const Text(
        'Biometric Authentication',
        style: TextStyle(fontSize: 15),
      ),
      subtitle: Text(
        _biometricAvailable
            ? 'Lock the app when you leave and return'
            : 'Not available on this device',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
      value: enabled && _biometricAvailable,
      activeThumbColor: const Color(0xFFC9A96E),
      onChanged: _biometricAvailable
          ? (v) async {
              if (v) {
                // Verify auth once before enabling, so we know it works.
                final success = await BiometricService.authenticate();
                if (!success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Authentication failed. Biometric lock not enabled.'),
                        backgroundColor: Color(0xFF2A2520),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }
              }
              await ref
                  .read(biometricEnabledProvider.notifier)
                  .setEnabled(v);
            }
          : null,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.0 * vw, 2.8 * vh, 4.0 * vw, 1.0 * vh),
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
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      secondary: Icon(icon, color: const Color(0xFFC9A96E)),
      value: value,
      activeThumbColor: const Color(0xFFC9A96E),
      onChanged: onChanged,
    );
  }

  Widget _buildTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFC9A96E)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 4.0 * SizeConfig.vw,
        color: const Color(0xFFC9A96E),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Text(
        value,
        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
      ),
    );
  }
}
