import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';

/// Handles all Supabase authentication operations.
///
/// This class is the single place where auth logic lives. Screens and
/// notifiers depend on this repository rather than calling Supabase directly.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

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
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      },
    );
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
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
