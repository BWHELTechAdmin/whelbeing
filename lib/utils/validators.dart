/// A single password strength requirement.
class PasswordRequirement {
  const PasswordRequirement({required this.label, required this.pattern});

  /// Human-readable label shown in the UI (e.g. 'One uppercase letter').
  final String label;

  /// Regex pattern string used to test the password.
  final String pattern;

  /// Returns true when [password] satisfies this requirement.
  bool isMet(String password) => RegExp(pattern).hasMatch(password);
}

/// Client-side validation helpers for the sign-up flow.
abstract final class Validators {
  /// Ordered list of password strength requirements.
  ///
  /// Single source of truth shared by [password] validation and the UI
  /// checklist widget.
  static final List<PasswordRequirement> passwordRequirements = [
    const PasswordRequirement(
        label: 'One uppercase letter', pattern: r'[A-Z]'),
    const PasswordRequirement(
        label: 'One lowercase letter', pattern: r'[a-z]'),
    const PasswordRequirement(label: 'One number', pattern: r'[0-9]'),
    const PasswordRequirement(
        label: 'One special character', pattern: r'[^a-zA-Z0-9]'),
  ];

  /// Returns an error message if [password] fails any requirement, or null.
  static String? password(String password) {
    for (final req in passwordRequirements) {
      if (!req.isMet(password)) {
        return 'Password must include at least ${req.label.toLowerCase()}.';
      }
    }
    return null;
  }
}
