/// When provided to [AndroidOptions], every encrypt/decrypt operation
/// requires biometric or device credential authentication via
/// `BiometricPrompt`. The key is generated with
/// `setUserAuthenticationRequired(true)` and
/// `setInvalidatedByBiometricEnrollment(true)`.
///
/// Requires `<uses-permission android:name="android.permission.USE_BIOMETRIC" />`
/// in your app's `AndroidManifest.xml`. Only effective on API 30+ (Android 11);
/// on API 29 authentication is silently ignored.
class AndroidAuthentication {
  const AndroidAuthentication({
    required this.promptTitle,
    required this.promptSubtitle,
  });

  /// Title displayed on the biometric prompt dialog.
  final String promptTitle;

  /// Subtitle displayed on the biometric prompt dialog.
  final String promptSubtitle;
}

class AndroidOptions {
  const AndroidOptions({
    this.prefix = 'oubliette',
    this.keyAlias = 'default_key',
    this.unlockedDeviceRequired = true,
    this.strongBox = false,
    this.authentication,
  });

  /// Prefix prepended to every storage key in SharedPreferences.
  final String prefix;

  /// Android Keystore alias used for the AES-256-GCM encryption key.
  final String keyAlias;

  /// When `true`, the hardware-backed key can only be used while the
  /// device is unlocked. Maps to `setUnlockedDeviceRequired` on the
  /// `KeyGenParameterSpec`.
  final bool unlockedDeviceRequired;

  /// When `true`, prefers StrongBox-backed key storage if the device
  /// supports it (`PackageManager.FEATURE_STRONGBOX_KEYSTORE`).
  /// Falls back silently to TEE if StrongBox is unavailable.
  final bool strongBox;

  /// When non-null, enables biometric/device credential authentication
  /// for every encrypt and decrypt operation.
  final AndroidAuthentication? authentication;
}
