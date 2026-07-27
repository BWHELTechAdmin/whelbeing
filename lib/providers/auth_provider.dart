import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_callback_handler.dart';

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

/// True only once Supabase has confirmed the signed-in user's email address.
final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.emailConfirmedAt != null;
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

/// True from Supabase's recovery callback until the temporary session is
/// deliberately signed out. This keeps a recovery session out of normal app
/// routing even after [AuthChangeEvent.userUpdated] is emitted.
final passwordRecoveryInProgressProvider = StateProvider<bool>((ref) => false);

/// The email address that needs a confirmation link resent or completed.
///
/// This is set when a returning user tries to sign in before confirming their
/// email address, so the root can show the verification screen with a resend
/// action rather than a generic credentials error.
final pendingEmailVerificationProvider = StateProvider<String?>((ref) => null);

/// Captures native auth callbacks before the widget tree is mounted.
final authCallbackHandlerProvider = Provider<AuthCallbackHandler>(
  (ref) => AuthCallbackHandler(),
);

final authCallbackStateProvider = Provider<AuthCallbackState>((ref) {
  final handler = ref.watch(authCallbackHandlerProvider);
  void listener() => ref.invalidateSelf();
  handler.state.addListener(listener);
  ref.onDispose(() => handler.state.removeListener(listener));
  return handler.state.value;
});

/// Selects the signed-out entry surface after a password recovery completes.
enum SignedOutEntry { onboarding, signIn }

final signedOutEntryProvider = StateProvider<SignedOutEntry>(
  (ref) => SignedOutEntry.onboarding,
);
