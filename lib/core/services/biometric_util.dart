import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricUtil {
  BiometricUtil._();
  static final BiometricUtil instance = BiometricUtil._();

  final LocalAuthentication _auth = LocalAuthentication();

  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  Future<void> initialize() async {
    try {
      _canCheckBiometrics = await _auth.canCheckBiometrics;
      _availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint('[BiometricUtil] canCheck=$_canCheckBiometrics available=$_availableBiometrics');
    } catch (e) {
      debugPrint('[BiometricUtil] initialize failed: $e');
      // Device doesn't support biometrics or plugin channel not ready.
      // Defaults (_canCheckBiometrics = false, _availableBiometrics = []) apply.
    }
  }

  bool get deviceHasBiometricCapability => _canCheckBiometrics;
  bool get deviceHasBiometricsEnabled => _availableBiometrics.isNotEmpty;
  bool get supportsFaceId => _availableBiometrics.contains(BiometricType.face);

  Future<bool> didAuthenticate() async {
    return _auth.authenticate(
      localizedReason: 'Authenticate to sign in to Batti Nala',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }

  Future<void> openSettingsForEnrollment() async {
    await AppSettings.openAppSettings(type: AppSettingsType.security);
  }
}
