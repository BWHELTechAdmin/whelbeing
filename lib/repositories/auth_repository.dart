import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';

/// Thrown when an email request is repeated before its cooldown expires.
class EmailRequestCooldownException implements Exception {
  const EmailRequestCooldownException(this.retryAfter);

  final Duration retryAfter;

  String get message =>
      'Please wait ${retryAfter.inSeconds} seconds before requesting another email.';

  @override
  String toString() => message;
}

/// Handles all Supabase authentication operations.
///
/// This class is the single place where auth logic lives. Screens and
/// notifiers depend on this repository rather than calling Supabase directly.
class AuthRepository {
  const AuthRepository(this._client, {UpdateUserRequest? updateUser})
    : _updateUser = updateUser;

  final SupabaseClient _client;
  final UpdateUserRequest? _updateUser;
  static const _emailRequestCooldown = Duration(seconds: 60);
  static final Map<String, DateTime> _lastEmailRequests = {};

  // ── Google ──────────────────────────────────────────────────────────────────

  /// Signs the user in via Google OAuth.
  ///
  /// Returns silently when the user dismisses the account picker.
  /// Throws [AuthException] on Supabase-side failures.
  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      // Must be a Web client ID (not iOS/Android) to obtain an ID token.
      serverClientId: SupabaseConfig.googleServerClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // User cancelled — not an error.

    final auth = await googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception(
        'Google sign-in did not return an ID token. '
        'Verify that googleServerClientId is set to a Web client ID.',
      );
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
  }

  // ── Apple ───────────────────────────────────────────────────────────────────

  /// Signs the user in via Apple ID (iOS only).
  ///
  /// Uses a SHA-256 hashed nonce to bind the Apple credential to the Supabase
  /// session — required by both Apple and Supabase for security.
  ///
  /// Returns silently when the user cancels. Throws on other failures.
  Future<void> signInWithApple() async {
    final rawNonce = _generateNonce();

    late AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256(rawNonce), // Apple receives the hashed nonce.
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return; // User cancelled.
      rethrow;
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple sign-in did not return an identity token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce, // Supabase receives the raw nonce for verification.
    );
  }

  // ── Email / password ────────────────────────────────────────────────

  /// Signs the user in with [email] and [password].
  /// Throws [AuthException] on invalid credentials.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Registers a new account with [email] and [password].
  ///
  /// If email confirmation is enabled in Supabase, the user will receive a
  /// verification email before the session is established.
  Future<void> signUpWithPassword({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    _debounceEmailRequest(email);
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.emailConfirmationRedirectUrl,
      data: {
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      },
    );
  }

  /// Signs in if needed, fetches fresh user data, and checks email confirmation.
  ///
  /// A password is necessary immediately after a confirmation-required sign-up,
  /// because Supabase does not create a session until the email is confirmed.
  Future<bool> isEmailVerified({
    required String email,
    String? password,
  }) async {
    if (_client.auth.currentUser?.email != email) {
      if (password == null) return false;
      await signInWithPassword(email: email, password: password);
    }

    final user = (await _client.auth.getUser()).user;
    final isVerified = user?.emailConfirmedAt != null;
    if (isVerified && _client.auth.currentSession != null) {
      await _client.auth.refreshSession();
    }
    return isVerified;
  }

  /// Sends another confirmation email for a pending email/password sign-up.
  Future<void> resendEmailVerification(String email) async {
    _debounceEmailRequest(email);
    await _client.auth.resend(
      email: email,
      type: OtpType.signup,
      emailRedirectTo: SupabaseConfig.emailConfirmationRedirectUrl,
    );
  }

  /// Sends a password-recovery link without revealing whether [email] exists.
  Future<void> requestPasswordReset(String email) async {
    _debounceEmailRequest(email);
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.passwordRecoveryRedirectUrl,
    );
  }

  /// Requests a change to the signed-in user's email address.
  ///
  /// Supabase sends confirmation email(s) before the new address takes effect.
  /// The redirect returns to this app so the callback handler can exchange the
  /// confirmation code and refresh the signed-in user.
  Future<void> updateEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final validationError = Validators.email(normalizedEmail);
    if (validationError != null) {
      throw ArgumentError.value(email, 'email', validationError);
    }

    _debounceEmailRequest(normalizedEmail);
    final attributes = UserAttributes(email: normalizedEmail);
    final updateUser = _updateUser;
    if (updateUser != null) {
      await updateUser(
        attributes,
        emailRedirectTo: SupabaseConfig.emailConfirmationRedirectUrl,
      );
      return;
    }

    await _client.auth.updateUser(
      attributes,
      emailRedirectTo: SupabaseConfig.emailConfirmationRedirectUrl,
    );
  }

  /// Replaces the password for the active recovery session.
  ///
  /// Supabase creates this temporary session only after the user opens a valid
  /// recovery link; callers must not invoke this from a normal sign-in flow.
  Future<void> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  /// Permanently deletes the current user and their server-side data.
  ///
  /// The Edge Function derives the user ID from the current JWT, deletes
  /// storage objects, and then deletes the auth user so database cascades
  /// remove all dependent records. The client only clears its local session
  /// after the server confirms deletion.
  Future<void> deleteAccount() async {
    await _client.functions.invoke('delete-account');
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  // ── Activity tracking ────────────────────────────────────────────────

  /// Records today as an active day for the current user.
  /// Safe to call multiple times per day — the DB ignores duplicate dates.
  Future<void> recordAppOpen() => _client.rpc('record_app_open');

  // ── Sign out ─────────────────────────────────────────────────────

  Future<void> signOut() => _client.auth.signOut();

  /// Writes `onboarding_complete: true` into the user's Supabase metadata.
  ///
  /// Supabase will emit a new [AuthState] after this succeeds, which causes
  /// [currentUserProvider] (and therefore [hasCompletedOnboardingProvider])
  /// to refresh automatically — no manual invalidation needed.
  Future<void> markOnboardingComplete() async {
    await _client.auth.updateUser(
      UserAttributes(data: {'onboarding_complete': true}),
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  /// Prevents rapid repeat requests for the same email address.
  ///
  /// The timestamp is recorded before calling Supabase so simultaneous taps
  /// cannot pass the check while the first request is in flight.
  static void _debounceEmailRequest(String email) {
    final key = email.trim().toLowerCase();
    final now = DateTime.now();
    final lastRequest = _lastEmailRequests[key];
    if (lastRequest != null) {
      final elapsed = now.difference(lastRequest);
      if (elapsed < _emailRequestCooldown) {
        throw EmailRequestCooldownException(_emailRequestCooldown - elapsed);
      }
    }
    _lastEmailRequests[key] = now;
  }
}

typedef UpdateUserRequest =
    Future<void> Function(UserAttributes attributes, {String? emailRedirectTo});
// ─── Provider ─────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
