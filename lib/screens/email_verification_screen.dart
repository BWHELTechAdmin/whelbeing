import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';
import '../utils/size_config.dart';

/// Blocks onboarding until Supabase confirms the newly-created email address.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.password,
    required this.onVerified,
    this.onBack,
  });

  final String email;
  final String? password;
  final VoidCallback onVerified;
  final VoidCallback? onBack;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _message;
  bool _isError = false;

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      final isVerified = await ref
          .read(authRepositoryProvider)
          .isEmailVerified(email: widget.email, password: widget.password);
      if (!mounted) return;
      if (isVerified) {
        widget.onVerified();
      } else {
        setState(() {
          _isError = true;
          _message =
              'Your email is not verified yet. Open the link we sent, then try again.';
        });
      }
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message =
            'Your email is not verified yet. Open the link we sent, then try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = 'We could not check your verification status. Try again.';
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resendEmailVerification(widget.email);
      if (!mounted) return;
      setState(() {
        _isError = false;
        _message = 'A new verification email has been sent.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = 'We could not resend the email. Please try again shortly.';
      });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6 * vw, vertical: 5 * vh),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18 * vw,
                  height: 18 * vw,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: const Color(0xFFC9A96E).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    color: const Color(0xFFC9A96E),
                    size: 8 * vw,
                  ),
                ),
                SizedBox(height: 3 * vh),
                Text(
                  'Verify your email',
                  style: TextStyle(
                    color: const Color(0xFFE8DCC8),
                    fontSize: 8 * vw,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.5 * vh),
                Text(
                  'We sent a verification link to\n${widget.email}. Open it to return to Whelbeing and continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF9B8C7A),
                    fontSize: 3.6 * vw,
                    height: 1.5,
                  ),
                ),
                if (_message != null) ...[
                  SizedBox(height: 3 * vh),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.5 * vw),
                    decoration: BoxDecoration(
                      color: _isError
                          ? const Color(0xFF2A1010)
                          : const Color(0xFF122116),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isError
                            ? const Color(0xFF5A2020)
                            : const Color(0xFF2D6940),
                      ),
                    ),
                    child: Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isError
                            ? const Color(0xFFE08080)
                            : const Color(0xFF9DDBA7),
                        fontSize: 3.2 * vw,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 5 * vh),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A96E),
                      foregroundColor: const Color(0xFF0D0D0D),
                      padding: EdgeInsets.symmetric(vertical: 2 * vh),
                    ),
                    child: _isChecking
                        ? SizedBox(
                            width: 5 * vw,
                            height: 5 * vw,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0D0D0D),
                            ),
                          )
                        : Text(
                            'I’ve verified my email',
                            style: TextStyle(
                              fontSize: 3.5 * vw,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 2 * vh),
                TextButton(
                  onPressed: _isResending ? null : _resendVerification,
                  child: _isResending
                      ? SizedBox(
                          width: 4 * vw,
                          height: 4 * vw,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFC9A96E),
                          ),
                        )
                      : Text(
                          'Resend verification email',
                          style: TextStyle(
                            color: const Color(0xFFC9A96E),
                            fontSize: 3.4 * vw,
                          ),
                        ),
                ),
                if (widget.onBack != null)
                  TextButton(
                    onPressed: widget.onBack,
                    child: Text(
                      'Back to sign in',
                      style: TextStyle(
                        color: const Color(0xFF9B8C7A),
                        fontSize: 3.4 * vw,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
