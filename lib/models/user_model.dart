/// App-level user data mirroring `public.users` + auth email.
///
/// See the `create_users_table` migration for the canonical column list.
class UserModel {
  const UserModel({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.avatarPath,
    required this.createdAt,
  });

  final String id;

  /// Email sourced from `auth.users` (not stored in `public.users`).
  final String? email;

  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;

  /// Supabase Storage path of a user-uploaded profile photo (`{userId}/avatar.jpg`).
  /// Null means use the OAuth provider photo or the default placeholder.
  final String? avatarPath;

  final DateTime createdAt;

  /// First name to use in greetings, e.g. "Welcome back, Maya".
  /// Falls back to "there" so greetings remain grammatical when name is absent.
  String get displayFirstName =>
      firstName?.isNotEmpty == true ? firstName! : 'there';

  /// Full name for profile headers. Falls back to a single name or em-dash.
  String get displayName {
    final parts = [
      if (firstName?.isNotEmpty == true) firstName!,
      if (lastName?.isNotEmpty == true) lastName!,
    ];
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  /// Human-readable join date, e.g. "Member since January 2026".
  String get memberSince {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return 'Member since ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  /// Formatted date of birth, e.g. "June 15, 1994".
  String? get formattedDateOfBirth {
    if (dateOfBirth == null) return null;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dateOfBirth!.month - 1]} ${dateOfBirth!.day}, ${dateOfBirth!.year}';
  }

  UserModel copyWith({
    String? email,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    Object? avatarPath = _sentinel,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatarPath: avatarPath == _sentinel
          ? this.avatarPath
          : avatarPath as String?,
      createdAt: createdAt,
    );
  }

  // Sentinel used by copyWith to distinguish "not provided" from explicit null.
  static const Object _sentinel = Object();

  factory UserModel.fromJson(Map<String, dynamic> json, {String? email}) {
    final dobStr = json['date_of_birth'] as String?;
    return UserModel(
      id: json['id'] as String,
      email: email,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      dateOfBirth: dobStr != null ? DateTime.parse(dobStr) : null,
      avatarPath: json['avatar_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
