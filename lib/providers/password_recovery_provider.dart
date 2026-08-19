import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../repositories/auth_repository.dart';

@immutable
class PasswordRecoveryState {
  const PasswordRecoveryState({
    this.isLoading = false,
    this.isComplete = false,
    this.error,
  });

  final bool isLoading;
  final bool isComplete;
  final String? error;

  PasswordRecoveryState copyWith({
    bool? isLoading,
    bool? isComplete,
    String? error,
    bool clearError = false,
  }) {
    return PasswordRecoveryState(
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PasswordRecoveryNotifier
    extends AutoDisposeNotifier<PasswordRecoveryState> {
  @override
  PasswordRecoveryState build() => const PasswordRecoveryState();

  Future<bool> requestReset(String email) async {
    state = state.copyWith(
      isLoading: true,
      isComplete: false,
      clearError: true,
    );
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      state = state.copyWith(isComplete: true);
      return true;
    } on EmailRequestCooldownException catch (e) {
      state = state.copyWith(error: e.message);
    } on AuthException {
      state = state.copyWith(
        error: 'We could not send a reset link right now. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        error: 'We could not send a reset link right now. Please try again.',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  Future<bool> updatePassword(String password) async {
    state = state.copyWith(
      isLoading: true,
      isComplete: false,
      clearError: true,
    );
    try {
      await ref.read(authRepositoryProvider).updatePassword(password);
      state = state.copyWith(isComplete: true);
      return true;
    } on AuthException {
      state = state.copyWith(
        error:
            'This reset link is no longer valid. Request a new link and try again.',
      );
    } catch (_) {
      state = state.copyWith(
        error: 'We could not update your password. Please try again.',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }
}

final passwordRecoveryProvider =
    AutoDisposeNotifierProvider<
      PasswordRecoveryNotifier,
      PasswordRecoveryState
    >(PasswordRecoveryNotifier.new);
