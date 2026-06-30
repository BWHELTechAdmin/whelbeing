import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBiometricEnabledKey = 'biometric_enabled';

/// Provides the [SharedPreferences] instance. Overridden in [main] so the
/// value is available synchronously before the widget tree builds.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

/// Notifier that stores whether biometric lock is enabled.
///
/// State is initialised synchronously from [SharedPreferences] and persisted
/// on every change, so it survives app restarts with no async gap.
class BiometricSettingNotifier extends StateNotifier<bool> {
  BiometricSettingNotifier(this._prefs)
      : super(_prefs.getBool(_kBiometricEnabledKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> setEnabled(bool value) async {
    state = value;
    await _prefs.setBool(_kBiometricEnabledKey, value);
  }
}

final biometricEnabledProvider =
    StateNotifierProvider<BiometricSettingNotifier, bool>((ref) {
  return BiometricSettingNotifier(ref.watch(sharedPreferencesProvider));
});
