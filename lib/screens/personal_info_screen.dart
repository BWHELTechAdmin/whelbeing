import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/size_config.dart';
import '../utils/validators.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _initialized = false;
  bool _uploadingAvatar = false;
  String? _originalEmail;
  String? _requestedEmailChange;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateFromUser(UserModel user) {
    _nameController.text = user.displayName == '—' ? '' : user.displayName;
    _emailController.text = user.email ?? '';
    _originalEmail = user.email?.trim().toLowerCase();
    _dateOfBirth = user.dateOfBirth;
  }

  Future<void> _save() async {
    final requestedEmail = _emailController.text.trim().toLowerCase();
    final emailChanged =
        requestedEmail != _originalEmail &&
        requestedEmail != _requestedEmailChange;
    if (emailChanged) {
      final validationError = Validators.email(requestedEmail);
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    setState(() => _isSaving = true);
    try {
      final fullName = _nameController.text.trim();
      final spaceIdx = fullName.indexOf(' ');
      final firstName = spaceIdx == -1
          ? fullName
          : fullName.substring(0, spaceIdx);
      final lastName = spaceIdx == -1 ? '' : fullName.substring(spaceIdx + 1);

      await ref
          .read(userRepositoryProvider)
          .updateUser(
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: _dateOfBirth,
          );
      if (emailChanged) {
        await ref.read(authRepositoryProvider).updateEmail(requestedEmail);
        _requestedEmailChange = requestedEmail;
      }

      ref.invalidate(currentUserModelProvider);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emailChanged
                  ? 'Profile updated. Check your email to confirm the new address.'
                  : 'Profile updated!',
            ),
            backgroundColor: Color(0xFFC9A96E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      _save();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
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
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    if (!_isEditing) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFFC9A96E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  String get _formattedDob {
    if (_dateOfBirth == null) return 'Not set';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[_dateOfBirth!.month - 1]} ${_dateOfBirth!.day}, ${_dateOfBirth!.year}';
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    // Populate controllers once when data first arrives
    final userAsync = ref.watch(currentUserModelProvider);
    ref.listen(currentUserModelProvider, (_, next) {
      if (!_initialized && next.valueOrNull != null) {
        _initialized = true;
        _populateFromUser(next.value!);
        setState(() {});
      }
    });
    if (!_initialized && userAsync.valueOrNull != null) {
      _initialized = true;
      _populateFromUser(userAsync.value!);
    }

    final memberSince = userAsync.valueOrNull?.memberSince ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personal Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC9A96E),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _toggleEdit,
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(
                  color: Color(0xFFE8DCC8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A96E)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load profile: $e',
            style: const TextStyle(color: Color(0xFFE8DCC8)),
          ),
        ),
        data: (_) => SingleChildScrollView(
          padding: EdgeInsets.all(4.0 * vw),
          child: Column(
            children: [
              SizedBox(height: 1.0 * vh),
              Center(
                child: GestureDetector(
                  onTap: _isEditing ? _pickAndUploadAvatar : null,
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1.0 * vw),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2A2520),
                          shape: BoxShape.circle,
                        ),
                        child: Builder(
                          builder: (context) {
                            final avatarUrl = ref
                                .watch(avatarUrlProvider)
                                .valueOrNull;
                            return CircleAvatar(
                              radius: 12.0 * vw,
                              backgroundColor: const Color(0xFF1A1A1A),
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 12.0 * vw,
                                      color: const Color(0xFFE8DCC8),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      if (_uploadingAvatar)
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
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(1.5 * vw),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC9A96E),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: const Color(0xFF1A1A1A),
                              size: 4.5 * vw,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 3.8 * vh),
              _buildField(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline,
              ),
              SizedBox(height: 2.0 * vh),
              _buildField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 2.0 * vh),
              _buildDateField(),
              SizedBox(height: 2.0 * vh),
              _buildReadOnlyField(
                label: 'Member Since',
                value: memberSince,
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
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
          Icon(icon, color: const Color(0xFFC9A96E), size: 5.5 * vw),
          SizedBox(width: 4.0 * vw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                SizedBox(height: 0.5 * vh),
                _isEditing
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFFE8DCC8),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        controller.text,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFFE8DCC8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: _pickDateOfBirth,
      child: Container(
        padding: EdgeInsets.all(4.0 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(3.0 * vw),
          border: Border.all(color: const Color(0xFF2A2520)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: const Color(0xFFC9A96E),
              size: 5.5 * vw,
            ),
            SizedBox(width: 4.0 * vw),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                  SizedBox(height: 0.5 * vh),
                  Text(
                    _formattedDob,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE8DCC8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_isEditing)
              Icon(
                Icons.edit_calendar,
                color: const Color(0xFFC9A96E),
                size: 5.0 * vw,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Container(
      padding: EdgeInsets.all(4.0 * vw),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2520).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3.0 * vw),
        border: Border.all(color: const Color(0xFF2A2520)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC9A96E), size: 5.5 * vw),
          SizedBox(width: 4.0 * vw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                SizedBox(height: 0.5 * vh),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
