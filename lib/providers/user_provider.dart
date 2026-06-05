import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

/// The current user's `public.users` row.
///
/// Automatically re-fetches when the Supabase session changes (sign-in /
/// sign-out / token refresh), so screens react without manual invalidation.
/// Returns null when the user is unauthenticated or the row doesn't exist yet.
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  ref.watch(currentSessionProvider); // Rebuild when auth state changes.
  return ref.read(userRepositoryProvider).fetchCurrentUser();
});

/// Resolves the display URL for the current user's avatar.
///
/// Priority:
///   1. Custom uploaded photo — generates a 7-day signed URL from Supabase Storage.
///   2. OAuth profile picture — `avatar_url` in Supabase auth metadata (Google).
///   3. null — caller shows the default placeholder.
final avatarUrlProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(currentUserModelProvider.future);
  final repo = ref.read(userRepositoryProvider);

  if (user?.avatarPath != null) {
    return repo.getAvatarSignedUrl(user!.avatarPath!);
  }

  // Fall back to OAuth profile picture (present for Google sign-ins).
  final authUser = ref.watch(currentUserProvider);
  final oauthAvatar = authUser?.userMetadata?['avatar_url'] as String?;
  return (oauthAvatar?.isNotEmpty == true) ? oauthAvatar : null;
});
