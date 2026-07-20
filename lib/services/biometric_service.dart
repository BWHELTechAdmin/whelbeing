import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the biometric lock preference in SharedPreferences and exposes
/// a global [ValueNotifier] so any widget can react to changes without
/// Riverpod or page-scoped local state.
///
/// Call [init] once in [main] before [runApp].
class BiometricSettings {
  BiometricSettings._();

  static SharedPreferences? _prefs;
  static const _key = 'biometric_enabled';

  /// Global reactive state — widgets use [ValueListenableBuilder] on this.
  static final notifier = ValueNotifier<bool>(false);

  /// Load (or reuse) the SharedPreferences instance and prime [notifier].
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    notifier.value = _prefs!.getBool(_key) ?? false;
  }

  /// Whether biometric lock is currently enabled.
  static bool get enabled => notifier.value;

  /// Persists a new value and updates [notifier] immediately so any
  /// listening widget rebuilds before the async disk write completes.
  static Future<void> setEnabled(bool value) async {
    notifier.value = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_key, value);
  }
}

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
