/// Client-side validation helpers for the sign-up flow.
abstract final class Validators {
  /// Returns an error message if [password] does not meet strength requirements,
  /// or null if it passes.
  ///
  /// Requirements:
  ///   - At least one uppercase letter (A-Z)
  ///   - At least one lowercase letter (a-z)
  ///   - At least one digit (0-9)
  ///   - At least one special character (anything non-alphanumeric)
  static String? password(String password) {
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    if (!password.contains(RegExp(r'[^a-zA-Z0-9]'))) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }
}
