import 'package:local_auth/local_auth.dart';

/// Thin wrapper around [LocalAuthentication] for biometric checks.
class BiometricService {
  static final _auth = LocalAuthentication();

  /// Returns true if the device supports any form of local authentication
  /// (biometrics or device PIN/passcode).
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types on this device.
  static Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Prompts the user to authenticate using biometrics or device PIN/passcode.
  ///
  /// Returns true on success, false if the user cancels or authentication fails.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access Whelbeing',
        options: const AuthenticationOptions(
          // Allow PIN/passcode fallback when biometrics fail or are unavailable.
          biometricOnly: false,
          // Keep the dialog alive if the app is backgrounded during auth.
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
