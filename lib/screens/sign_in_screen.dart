import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/sign_in_provider.dart';
import '../utils/size_config.dart';
import '../utils/validators.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Sign-in / sign-up screen.
///
/// Email + password are the primary method; Google and Apple OAuth are offered
/// below a divider. All auth logic lives in [SignInNotifier] / [AuthRepository].
/// The screen auto-pops when [isAuthenticatedProvider] flips to true.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    final notifier = ref.read(signInProvider.notifier);

    if (!_isSignUp) {
      notifier.signInWithEmail(email, password);
      return;
    }

    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) return;

    // Password strength
    final passwordError = Validators.password(password);
    if (passwordError != null) {
      setState(() => _localError = passwordError);
      return;
    }

    setState(() => _localError = null);
    notifier.signUpWithEmail(
      email,
      password,
      firstName: firstName,
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isAuthenticatedProvider, (_, isAuthenticated) {
      if (isAuthenticated && context.mounted) Navigator.of(context).pop();
    });

    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    final state = ref.watch(signInProvider);
    final notifier = ref.read(signInProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back ──────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(5 * vw, 2 * vh, 0, 0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF6A5A4A),
                  size: 5.5 * vw,
                ),
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(6 * vw, 3 * vh, 6 * vw, 4 * vh),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _isSignUp ? 'Create\naccount.' : 'Welcome\nback.',
                        key: ValueKey(_isSignUp),
                        style: TextStyle(
                          fontSize: 9.5 * vw,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE8DCC8),
                          height: 1.08,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.5 * vh),
                    Text(
                      _isSignUp
                          ? 'Join BWhel and take control of your health.'
                          : 'Sign in to continue your health journey.',
                      style: TextStyle(
                        fontSize: 3.5 * vw,
                        color: const Color(0xFF5A4A3A),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 4 * vh),

                    // Error banner
                    if (_localError != null || state.error != null) ...[
                      _ErrorBanner(message: _localError ?? state.error!, vw: vw, vh: vh),
                      SizedBox(height: 2.5 * vh),
                    ],

                    // Name fields — sign-up only
                    if (_isSignUp) ...[
                      _InputField(
                        controller: _firstNameController,
                        hint: 'First name',
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        vw: vw,
                        vh: vh,
                      ),
                      SizedBox(height: 1.5 * vh),
                      _InputField(
                        controller: _lastNameController,
                        hint: 'Last name (optional)',
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        vw: vw,
                        vh: vh,
                      ),
                      SizedBox(height: 1.5 * vh),
                    ],

                    // Email field
                    _InputField(
                      controller: _emailController,
                      hint: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      vw: vw,
                      vh: vh,
                    ),
                    SizedBox(height: 1.5 * vh),

                    // Password field
                    _InputField(
                      controller: _passwordController,
                      hint: 'Password',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      vw: vw,
                      vh: vh,
                      suffix: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3 * vw),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF5A4A3A),
                            size: 5 * vw,
                          ),
                        ),
                      ),
                    ),

                    // Forgot password — sign-in mode only
                    // if (!_isSignUp) ...[
                    //   SizedBox(height: 1.5 * vh),
                    //   Align(
                    //     alignment: Alignment.centerRight,
                    //     child: GestureDetector(
                    //       onTap: () {/* TODO: forgot password */},
                    //       child: Text(
                    //         'Forgot password?',
                    //         style: TextStyle(
                    //           fontSize: 3.0 * vw,
                    //           color: const Color(0xFF6A5A4A),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ],
                    SizedBox(height: 3 * vh),

                    // Email submit button
                    _SubmitButton(
                      label: _isSignUp ? 'Create Account' : 'Sign In',
                      loading: state.loadingEmail,
                      disabled: state.isLoading,
                      onTap: _submit,
                      vw: vw,
                      vh: vh,
                    ),
                    SizedBox(height: 4 * vh),

                    // // Divider
                    // _OrDivider(vw: vw),
                    // SizedBox(height: 4 * vh),

                    // // Google OAuth
                    // _AuthButton(
                    //   label: 'Continue with Google',
                    //   iconWidget: Text(
                    //     'G',
                    //     style: TextStyle(
                    //       fontSize: 5 * vw,
                    //       fontWeight: FontWeight.w700,
                    //       color: const Color(0xFF4285F4),
                    //     ),
                    //   ),
                    //   loading: state.loadingGoogle,
                    //   disabled: state.isLoading,
                    //   onTap: notifier.signInWithGoogle,
                    //   vh: vh,
                    //   vw: vw,
                    // ),

                    // // Apple OAuth — iOS only
                    // if (Platform.isIOS) ...[
                    //   SizedBox(height: 1.5 * vh),
                    //   _AuthButton(
                    //     label: 'Continue with Apple',
                    //     iconWidget: Text(
                    //       '\uF8FF',
                    //       style: TextStyle(
                    //         fontSize: 5.5 * vw,
                    //         color: const Color(0xFFE8DCC8),
                    //       ),
                    //     ),
                    //     loading: state.loadingApple,
                    //     disabled: state.isLoading,
                    //     onTap: notifier.signInWithApple,
                    //     vh: vh,
                    //     vw: vw,
                    //   ),
                    // ],
                    SizedBox(height: 4 * vh),

                    // Sign-in / sign-up toggle
                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _isSignUp = !_isSignUp),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 3.2 * vw),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'Already a member?  '
                                    : "Don't have an account?  ",
                                style: const TextStyle(
                                    color: Color(0xFF4A3A2A)),
                              ),
                              TextSpan(
                                text: _isSignUp ? 'Sign in' : 'Sign up',
                                style: const TextStyle(
                                  color: Color(0xFF9A7830),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF9A7830),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(
      {required this.message, required this.vw, required this.vh});

  final String message;
  final double vw;
  final double vh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.5 * vw),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1010),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5A2020)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 3.0 * vw,
          color: const Color(0xFFE08080),
          height: 1.5,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    required this.vw,
    required this.vh,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final double vw;
  final double vh;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: 4.0 * vw, color: const Color(0xFFE8DCC8)),
      cursorColor: const Color(0xFFC9A96E),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 4.0 * vw, color: const Color(0xFF3A2E24)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 4.5 * vw, vertical: 2 * vh),
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
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.vw,
    required this.vh,
  });

  final String label;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  final double vw;
  final double vh;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.1 * vh),
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFC9A96E), Color(0xFF8B6914)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: disabled ? const Color(0xFF141414) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? const Color(0xFF222220) : Colors.transparent,
          ),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFC9A96E).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 5.5 * vw,
                  height: 5.5 * vw,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: disabled
                        ? const Color(0xFF4A4A4A)
                        : const Color(0xFF0D0D0D),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 3.4 * vw,
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFF0D0D0D),
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.vw});

  final double vw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF1E1E1A), height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3 * vw),
          child: Text(
            'or',
            style: TextStyle(fontSize: 3.0 * vw, color: const Color(0xFF3A3028)),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF1E1E1A), height: 1)),
      ],
    );
  }
}

// ─── Auth button ─────────────────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.iconWidget,
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.vh,
    required this.vw,
  });

  final String label;
  final Widget iconWidget;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  final double vh;
  final double vw;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.1 * vh, horizontal: 5 * vw),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: loading
                ? const Color(0xFF1E1E1A)
                : const Color(0xFF2A2520),
          ),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 5.5 * vw,
                  height: 5.5 * vw,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC9A96E),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  SizedBox(width: 3.5 * vw),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 3.8 * vw,
                      color: const Color(0xFFE8DCC8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
