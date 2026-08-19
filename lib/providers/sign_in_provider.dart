import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../providers/auth_provider.dart';

import '../repositories/auth_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the sign-in screen's loading / error state.
@immutable
class SignInState {
  const SignInState({
    this.loadingGoogle = false,
    this.loadingApple = false,
    this.loadingEmail = false,
    this.error,
  });

  final bool loadingGoogle;
  final bool loadingApple;
  final bool loadingEmail;
  final String? error;

  bool get isLoading => loadingGoogle || loadingApple || loadingEmail;

  SignInState copyWith({
    bool? loadingGoogle,
    bool? loadingApple,
    bool? loadingEmail,
    String? error,
    bool clearError = false,
  }) {
    return SignInState(
      loadingGoogle: loadingGoogle ?? this.loadingGoogle,
      loadingApple: loadingApple ?? this.loadingApple,
      loadingEmail: loadingEmail ?? this.loadingEmail,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SignInNotifier extends AutoDisposeNotifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  Future<void> signInWithGoogle() async {
    state = state.copyWith(loadingGoogle: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loadingGoogle: false);
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(loadingApple: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loadingApple: false);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(loadingEmail: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        ref.read(pendingEmailVerificationProvider.notifier).state = email;
        return;
      }
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loadingEmail: false);
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    state = state.copyWith(loadingEmail: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithPassword(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
          );
      return true;
    } on EmailRequestCooldownException catch (e) {
      state = state.copyWith(error: e.message);
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loadingEmail: false);
    }
    return false;
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Auto-disposed so state resets whenever the sign-in screen is closed.
final signInProvider = AutoDisposeNotifierProvider<SignInNotifier, SignInState>(
  SignInNotifier.new,
);
