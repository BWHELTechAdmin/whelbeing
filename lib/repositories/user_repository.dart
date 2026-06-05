import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';

/// Handles all reads/writes to `public.users`.
class UserRepository {
  const UserRepository(this._client);

  final SupabaseClient _client;

  /// Returns the current user's profile row, or null when unauthenticated or
  /// the row hasn't been created yet.
  ///
  /// Email is sourced from the live auth session rather than stored in
  /// `public.users` to avoid duplication.
  Future<UserModel?> fetchCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final data = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data, email: authUser.email);
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  /// Uploads [bytes] as the user's profile photo and records the path.
  ///
  /// Always writes to `{userId}/avatar.jpg` with upsert, so uploading a new
  /// photo automatically replaces the previous one without orphaning files.
  Future<void> uploadAvatar(Uint8List bytes) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final path = '$userId/avatar.jpg';
    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    await _client
        .from('users')
        .update({'avatar_path': path})
        .eq('id', userId);
  }

  /// Deletes the user's custom avatar from storage and clears `avatar_path`.
  Future<void> removeAvatar() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    // Best-effort delete — ignore errors if the object doesn't exist.
    try {
      await _client.storage
          .from('avatars')
          .remove(['$userId/avatar.jpg']);
    } catch (_) {}
    await _client
        .from('users')
        .update({'avatar_path': null})
        .eq('id', userId);
  }

  /// Returns a 7-day signed URL for the given storage [path], or null on error.
  Future<String?> getAvatarSignedUrl(String path) async {
    try {
      return await _client.storage
          .from('avatars')
          .createSignedUrl(path, 60 * 60 * 24 * 7);
    } catch (_) {
      return null;
    }
  }

  // ── Profile fields ────────────────────────────────────────────────────────

  /// Updates editable profile fields. Only non-null arguments are written.
  Future<void> updateUser({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName.isEmpty ? null : firstName;
    if (lastName != null) data['last_name'] = lastName.isEmpty ? null : lastName;
    if (dateOfBirth != null) {
      data['date_of_birth'] =
          '${dateOfBirth.year.toString().padLeft(4, '0')}-'
          '${dateOfBirth.month.toString().padLeft(2, '0')}-'
          '${dateOfBirth.day.toString().padLeft(2, '0')}';
    }

    if (data.isEmpty) return;
    await _client.from('users').update(data).eq('id', userId);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(supabaseClientProvider));
});
