import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/password_recovery_provider.dart';
import '../utils/size_config.dart';
import '../utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final emailError = Validators.email(email);
    if (emailError != null) {
      setState(() => _localError = emailError);
      return;
    }

    setState(() => _localError = null);
    await ref.read(passwordRecoveryProvider.notifier).requestReset(email);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final state = ref.watch(passwordRecoveryProvider);
    final error = _localError ?? state.error;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(6 * vw, 2 * vh, 6 * vw, 5 * vh),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: state.isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF6A5A4A),
                  size: 5.5 * vw,
                ),
              ),
              SizedBox(height: 7 * vh),
              Text(
                state.isComplete
                    ? 'Check your\nemail.'
                    : 'Reset your\npassword.',
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
                    ? 'If an account exists for this email, we sent a secure reset link. Open it on this device to choose a new password.'
                    : 'Enter your email address and we’ll send a secure link to reset your password.',
                style: TextStyle(
                  color: const Color(0xFF9B8C7A),
                  fontSize: 3.6 * vw,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 5 * vh),
              if (!state.isComplete) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    fontSize: 4 * vw,
                    color: const Color(0xFFE8DCC8),
                  ),
                  cursorColor: const Color(0xFFC9A96E),
                  decoration: _inputDecoration('Email address', vw, vh),
                ),
                if (error != null) ...[
                  SizedBox(height: 1.8 * vh),
                  _RecoveryMessage(message: error, isError: true, vw: vw),
                ],
                SizedBox(height: 3 * vh),
                _RecoveryButton(
                  label: 'Send reset link',
                  loading: state.isLoading,
                  onPressed: _submit,
                  vw: vw,
                  vh: vh,
                ),
              ] else ...[
                _RecoveryMessage(
                  message:
                      'For your security, the link expires and can only be used once.',
                  isError: false,
                  vw: vw,
                ),
                SizedBox(height: 3 * vh),
                _RecoveryButton(
                  label: 'Back to sign in',
                  onPressed: () => Navigator.of(context).pop(),
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

InputDecoration _inputDecoration(String hint, double vw, double vh) {
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

class _RecoveryMessage extends StatelessWidget {
  const _RecoveryMessage({
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

class _RecoveryButton extends StatelessWidget {
  const _RecoveryButton({
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
