import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw Supabase client — single source of truth for all Supabase calls.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Reactive stream of every [AuthState] emitted by Supabase.
///
/// Use this to react to sign-in / sign-out / token-refresh events without
/// manually managing a [StreamSubscription].
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// The active [Session], or null when the user is signed out.
///
/// Prefers the latest value from [authStateChangesProvider] (reactive) and
/// falls back to [GoTrueClient.currentSession] while the stream is still
/// loading (i.e. before the first auth event arrives on app start).
final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStateChangesProvider).valueOrNull?.session ??
      ref.watch(supabaseClientProvider).auth.currentSession;
});

/// True while a valid Supabase session exists.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionProvider) != null;
});

/// The signed-in [User], or null when unauthenticated.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(currentSessionProvider)?.user;
});

/// True when the signed-in user has a persisted `onboarding_complete` flag
/// in their Supabase user metadata.
///
/// Returns false for unauthenticated users and for authenticated users who
/// signed up (via any method) but haven't finished the health-profile flow
/// yet. Automatically updates when [currentUserProvider] refreshes after
/// [AuthRepository.markOnboardingComplete] writes to Supabase.
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.userMetadata?['onboarding_complete'] == true;
});
