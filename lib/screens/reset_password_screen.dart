import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/password_recovery_provider.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_callback_handler.dart';
import '../utils/size_config.dart';
import '../utils/validators.dart';
import '../widgets/password_requirements.dart';

/// The only route that may update a password from an email recovery session.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.callbackError,
    this.isProcessingCallback = false,
  });

  final String? callbackError;
  final bool isProcessingCallback;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isReturningToSignIn = false;
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final passwordError = Validators.password(password);
    if (passwordError != null) {
      setState(() => _localError = passwordError);
      return;
    }
    if (password != _confirmationController.text) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }

    setState(() => _localError = null);
    await ref.read(passwordRecoveryProvider.notifier).updatePassword(password);
  }

  Future<void> _returnToSignIn() async {
    if (_isReturningToSignIn) return;
    setState(() => _isReturningToSignIn = true);
    ref.read(authCallbackHandlerProvider).clear();
    ref.read(signedOutEntryProvider.notifier).state = SignedOutEntry.signIn;
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _localError = 'We could not open the sign-in screen. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isReturningToSignIn = false);
    }
  }

  void _goBack() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final state = ref.watch(passwordRecoveryProvider);
    final callbackState = ref.watch(authCallbackStateProvider);
    final hasRecoverySession = ref.watch(currentSessionProvider) != null;
    final error = _localError ?? state.error;
    final callbackError =
        callbackState.kind == AuthCallbackKind.passwordRecovery
        ? callbackState.errorMessage
        : widget.callbackError;
    final isProcessingCallback =
        callbackState.kind == AuthCallbackKind.passwordRecovery
        ? callbackState.isProcessing
        : widget.isProcessingCallback;
    final isExpired = callbackError != null || !hasRecoverySession;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isReturningToSignIn ? null : _goBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(6 * vw, 7 * vh, 6 * vw, 5 * vh),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.isComplete
                    ? 'Password\nupdated.'
                    : isProcessingCallback
                    ? 'Opening secure\nlink.'
                    : hasRecoverySession
                    ? 'Choose a new\npassword.'
                    : 'This link has\nexpired.',
                style: TextStyle(
                  color: const Color(0xFFE8DCC8),
                  fontSize: 9.5 * vw,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 1.7 * vh),
              Text(
                state.isComplete
                    ? 'Your password was changed successfully. Sign in with your new password to continue.'
                    : isProcessingCallback
                    ? 'We are securely opening your password reset request.'
                    : hasRecoverySession
                    ? 'Create a strong password that you have not used before.'
                    : callbackError ??
                          'For your security, password reset links can only be used once. Return to sign in to request a new link.',
                style: TextStyle(
                  color: const Color(0xFF9B8C7A),
                  fontSize: 3.6 * vw,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 5 * vh),
              if (isProcessingCallback)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC9A96E)),
                )
              else if (state.isComplete)
                _ResetButton(
                  label: 'Sign in',
                  onPressed: _returnToSignIn,
                  loading: _isReturningToSignIn,
                  vw: vw,
                  vh: vh,
                )
              else if (isExpired)
                _ResetButton(
                  label: 'Return to sign in',
                  onPressed: _returnToSignIn,
                  loading: _isReturningToSignIn,
                  vw: vw,
                  vh: vh,
                )
              else ...[
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 4 * vw,
                    color: const Color(0xFFE8DCC8),
                  ),
                  cursorColor: const Color(0xFFC9A96E),
                  decoration: _resetInputDecoration('New password', vw, vh)
                      .copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF5A4A3A),
                          ),
                        ),
                      ),
                ),
                SizedBox(height: 1.5 * vh),
                TextField(
                  controller: _confirmationController,
                  obscureText: _obscureConfirmation,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _updatePassword(),
                  style: TextStyle(
                    fontSize: 4 * vw,
                    color: const Color(0xFFE8DCC8),
                  ),
                  cursorColor: const Color(0xFFC9A96E),
                  decoration:
                      _resetInputDecoration(
                        'Confirm new password',
                        vw,
                        vh,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF5A4A3A),
                          ),
                        ),
                      ),
                ),
                SizedBox(height: 1.5 * vh),
                PasswordRequirementsChecklist(
                  controller: _passwordController,
                  vw: vw,
                  vh: vh,
                ),
                if (error != null) ...[
                  SizedBox(height: 1.8 * vh),
                  _ResetMessage(message: error, isError: true, vw: vw),
                ],
                SizedBox(height: 3 * vh),
                _ResetButton(
                  label: 'Update password',
                  loading: state.isLoading,
                  onPressed: _updatePassword,
                  vw: vw,
                  vh: vh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _resetInputDecoration(String hint, double vw, double vh) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 4 * vw, color: const Color(0xFF3A2E24)),
    filled: true,
    fillColor: const Color(0xFF111111),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 4.5 * vw,
      vertical: 2 * vh,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2A2520)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: const Color(0xFFC9A96E).withValues(alpha: 0.55),
        width: 1.5,
      ),
    ),
  );
}

class _ResetMessage extends StatelessWidget {
  const _ResetMessage({
    required this.message,
    required this.isError,
    required this.vw,
  });

  final String message;
  final bool isError;
  final double vw;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.5 * vw),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFF2A1010) : const Color(0xFF122116),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFF5A2020) : const Color(0xFF2D6940),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFE08080) : const Color(0xFF9DDBA7),
          fontSize: 3.2 * vw,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.label,
    required this.onPressed,
    required this.vw,
    required this.vh,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double vw;
  final double vh;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFC9A96E),
          foregroundColor: const Color(0xFF0D0D0D),
          padding: EdgeInsets.symmetric(vertical: 2 * vh),
        ),
        child: loading
            ? SizedBox(
                width: 5 * vw,
                height: 5 * vw,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0D0D0D),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 3.5 * vw,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
