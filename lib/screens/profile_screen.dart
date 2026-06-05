import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../widgets/gold_shimmer.dart';
import '../utils/size_config.dart';
import 'settings_screen.dart';
import 'personal_info_screen.dart';
import 'privacy_screen.dart';
import 'help_center_screen.dart';
import 'about_screen.dart';

// ── Internal action enum ───────────────────────────────────────────────────

enum _AvatarAction { gallery, camera, remove }

// ── Screen ─────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    final userAsync = ref.watch(currentUserModelProvider);
    final avatarAsync = ref.watch(avatarUrlProvider);

    final displayName = userAsync.valueOrNull?.displayName ?? '—';
    final memberSince = userAsync.valueOrNull?.memberSince ?? '';
    final avatarUrl = avatarAsync.valueOrNull;
    final hasCustomAvatar = userAsync.valueOrNull?.avatarPath != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          children: [
            _buildProfileHeader(
              displayName: displayName,
              memberSince: memberSince,
              avatarUrl: avatarUrl,
              hasCustomAvatar: hasCustomAvatar,
              vw: vw,
              vh: vh,
            ),
            SizedBox(height: 2.8 * vh),
            _buildMenuSection(
              'Account',
              [
                _buildMenuItem(
                  context,
                  Icons.person_outline,
                  'Personal Information',
                  'Update your details',
                  const PersonalInfoScreen(),
                ),
                _buildMenuItem(
                  context,
                  Icons.lock_outline,
                  'Privacy & Security',
                  'Control your data',
                  const PrivacyScreen(),
                ),
              ],
            ),
            SizedBox(height: 2.0 * vh),
            _buildMenuSection(
              'Support',
              [
                _buildMenuItem(
                  context,
                  Icons.help_outline,
                  'Help Center',
                  'Get answers to your questions',
                  const HelpCenterScreen(),
                ),
                _buildMenuItem(
                  context,
                  Icons.info_outline,
                  'About',
                  'Learn more about Whelbeing',
                  const AboutScreen(),
                ),
              ],
            ),
            SizedBox(height: 2.8 * vh),
            Semantics(
              label: 'Log out of your account',
              button: true,
              child: TextButton(
                style: TextButton.styleFrom(
                  // Enforce WCAG 2.5.5 minimum touch target (44×44pt)
                  minimumSize: const Size(88, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 44),
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFFC9A96E)),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 44),
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            }
                          },
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: Color(0xFFE8DCC8)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFFC9A96E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.0 * vh),
          ],
        ),
      ),
    );
  }

  // ── Avatar actions ───────────────────────────────────────────────────

  Future<void> _onAvatarTap({required bool hasCustomAvatar}) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AvatarPickerSheet(hasCustomAvatar: hasCustomAvatar),
    );

    if (action == null || !mounted) return;

    if (action == _AvatarAction.remove) {
      setState(() => _uploading = true);
      try {
        await ref.read(userRepositoryProvider).removeAvatar();
        ref.invalidate(currentUserModelProvider);
        ref.invalidate(avatarUrlProvider);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove photo.')),
          );
        }
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
      return;
    }

    final picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(
      source: action == _AvatarAction.gallery
          ? ImageSource.gallery
          : ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (xFile == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await xFile.readAsBytes();
      await ref.read(userRepositoryProvider).uploadAvatar(bytes);
      ref.invalidate(currentUserModelProvider);
      ref.invalidate(avatarUrlProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile photo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildProfileHeader({
    required String displayName,
    required String memberSince,
    required String? avatarUrl,
    required bool hasCustomAvatar,
    required double vw,
    required double vh,
  }) {
    final ringPad = 0.75 * vw;
    final avatarRadius = 9.0 * vw;
    final totalSize = avatarRadius * 2 + ringPad * 2;

    return GoldShimmerContainer(
      padding: EdgeInsets.symmetric(horizontal: 6.0 * vw, vertical: 2.4 * vh),
      child: Row(
        children: [
          // ── Tappable avatar with camera badge ────────────────────────
          GestureDetector(
            onTap: () => _onAvatarTap(hasCustomAvatar: hasCustomAvatar),
            child: SizedBox(
              width: totalSize,
              height: totalSize,
              child: Stack(
                children: [
                  // Gold ring + photo
                  Container(
                    width: totalSize,
                    height: totalSize,
                    padding: EdgeInsets.all(ringPad),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC9A96E),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: const Color(0xFF1E1E1E),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: avatarRadius,
                              color: const Color(0xFFE8DCC8),
                            )
                          : null,
                    ),
                  ),
                  // Loading overlay while uploading
                  if (_uploading)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFC9A96E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Camera badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252018),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0D0D0D),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 3.5 * vw,
                        color: const Color(0xFFC9A96E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 5.0 * vw),
          // ── Name + member since ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5 * vh),
                Text(
                  memberSince,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 1.2 * vh),
                GestureDetector(
                  onTap: () =>
                      _onAvatarTap(hasCustomAvatar: hasCustomAvatar),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.5 * vw,
                      vertical: 0.5 * vh,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A96E).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5.0 * vw),
                      border: Border.all(
                        color: const Color(0xFFC9A96E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Edit Photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC9A96E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 1.0 * vw, bottom: 1.5 * vh),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8DCC8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(4.0 * vw),
            border: Border.all(
              color: const Color(0xFF2A2520),
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      String subtitle, Widget destination) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => destination,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.0 * vw, vertical: 1.7 * vh),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.0 * vw),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.0 * vw),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE8DCC8),
                size: 5.0 * vw,
              ),
            ),
            SizedBox(width: 4.0 * vw),
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
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
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
    );
  }
}

// ── Avatar picker bottom sheet ──────────────────────────────────────────────────

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({required this.hasCustomAvatar});

  final bool hasCustomAvatar;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vw = SizeConfig.vw;
    final vh = SizeConfig.vh;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.5 * vh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 10 * vw,
              height: 0.45 * vh,
              margin: EdgeInsets.only(bottom: 2 * vh),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3028),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            _tile(context, 'Choose from Library',
                Icons.photo_library_outlined, _AvatarAction.gallery, vw, vh),
            _tile(context, 'Take a Photo',
                Icons.camera_alt_outlined, _AvatarAction.camera, vw, vh),
            if (hasCustomAvatar) ...[
              Divider(
                height: 1,
                color: const Color(0xFF2A2520),
                indent: 4 * vw,
                endIndent: 4 * vw,
              ),
              SizedBox(height: 0.5 * vh),
              _tile(context, 'Remove Photo',
                  Icons.delete_outline_rounded, _AvatarAction.remove, vw, vh,
                  destructive: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String label,
    IconData icon,
    _AvatarAction action,
    double vw,
    double vh, {
    bool destructive = false,
  }) {
    final color =
        destructive ? const Color(0xFFE08080) : const Color(0xFFE8DCC8);
    return ListTile(
      leading: Icon(icon, color: color, size: 6 * vw),
      title: Text(label, style: TextStyle(color: color, fontSize: 4 * vw)),
      onTap: () => Navigator.of(context).pop(action),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 6 * vw,
        vertical: 0.3 * vh,
      ),
    );
  }
}
