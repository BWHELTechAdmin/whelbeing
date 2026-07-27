import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthCallbackKind { none, passwordRecovery, emailConfirmation }

class AuthCallbackState {
  const AuthCallbackState({
    this.kind = AuthCallbackKind.none,
    this.isProcessing = false,
    this.errorMessage,
  });

  final AuthCallbackKind kind;
  final bool isProcessing;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  AuthCallbackState copyWith({
    AuthCallbackKind? kind,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthCallbackState(
      kind: kind ?? this.kind,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Handles only this app's Supabase callback links.
///
/// Capturing the link before the widget tree is created prevents a cold-start
/// recovery callback from being lost before Riverpod subscribes to auth events.
class AuthCallbackHandler {
  AuthCallbackHandler({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final ValueNotifier<AuthCallbackState> state = ValueNotifier(
    const AuthCallbackState(),
  );
  final Set<String> _handledLinks = {};
  final List<Uri> _pendingLinks = [];
  late final StreamSubscription<Uri> _subscription;
  Future<void> Function(Uri)? _exchangeSession;

  Future<void> start() async {
    _subscription = _appLinks.uriLinkStream.listen(_receive);
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) _receive(initialLink);
  }

  Future<void> attachSupabase() async {
    _exchangeSession = Supabase.instance.client.auth.getSessionFromUrl;
    for (final uri in List<Uri>.from(_pendingLinks)) {
      await _process(uri);
    }
    _pendingLinks.clear();
  }

  void clear() => state.value = const AuthCallbackState();

  void dispose() {
    _subscription.cancel();
    state.dispose();
  }

  void _receive(Uri uri) {
    if (_kindFor(uri) == AuthCallbackKind.none) return;
    if (_exchangeSession == null) {
      _pendingLinks.add(uri);
      return;
    }
    unawaited(_process(uri));
  }

  Future<void> _process(Uri uri) async {
    final kind = _kindFor(uri);
    if (kind == AuthCallbackKind.none || !_handledLinks.add(uri.toString())) {
      return;
    }

    state.value = AuthCallbackState(kind: kind, isProcessing: true);
    try {
      await _exchangeSession!(uri);
      state.value = AuthCallbackState(kind: kind);
    } on AuthException {
      state.value = AuthCallbackState(
        kind: kind,
        errorMessage: kind == AuthCallbackKind.passwordRecovery
            ? 'This reset link has expired or has already been used. '
                  'Request a new link to continue.'
            : 'This verification link has expired or is no longer valid. '
                  'Request a new verification email to continue.',
      );
    } catch (_) {
      state.value = AuthCallbackState(
        kind: kind,
        errorMessage: 'We could not open this secure link. Please try again.',
      );
    }
  }

  AuthCallbackKind _kindFor(Uri uri) {
    if (uri.scheme != 'com.bwhel.whelbeing') return AuthCallbackKind.none;
    return switch (uri.host) {
      'reset-password' => AuthCallbackKind.passwordRecovery,
      'email-confirmed' => AuthCallbackKind.emailConfirmation,
      _ => AuthCallbackKind.none,
    };
  }
}
