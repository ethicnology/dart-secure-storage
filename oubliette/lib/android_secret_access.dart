/// Controls how secrets are protected on Android.
///
/// Use one of the named constructors to select a security profile:
/// - [AndroidSecretAccess.evenLocked] — accessible even when the device is locked (after first unlock).
/// - [AndroidSecretAccess.onlyUnlocked] — accessible only while the device is unlocked.
/// - [AndroidSecretAccess.biometric] — requires biometric/credential auth; survives biometric enrollment changes.
/// - [AndroidSecretAccess.biometricFatal] — requires biometric/credential auth; key is permanently invalidated if biometric enrollment changes.
class AndroidSecretAccess {
  /// Accessible even when the device is locked, as long as it has been
  /// Maps to `setUnlockedDeviceRequired(false)` on the `KeyGenParameterSpec`.
  const AndroidSecretAccess.evenLocked({
    this.prefix = 'oubliette',
    this.keyAlias = 'default_key',
  }) : unlockedDeviceRequired = false,
       promptTitle = null,
       promptSubtitle = null,
       invalidatedByBiometricEnrollment = false,
       strongBox = false;

  /// Accessible only while the device is unlocked. Maps to
  /// `setUnlockedDeviceRequired(true)` on the `KeyGenParameterSpec`.
  const AndroidSecretAccess.onlyUnlocked({
    this.prefix = 'oubliette',
    this.keyAlias = 'default_key',
    required this.strongBox,
  }) : unlockedDeviceRequired = true,
       promptTitle = null,
       promptSubtitle = null,
       invalidatedByBiometricEnrollment = false;

  /// Requires biometric or device credential authentication for every
  /// encrypt/decrypt operation. The key survives biometric enrollment
  /// changes (e.g. new fingerprint added).
  ///
  /// Requires `<uses-permission android:name="android.permission.USE_BIOMETRIC" />`
  /// in your app's `AndroidManifest.xml`. Only effective on API 30+ (Android 11).
  const AndroidSecretAccess.biometric({
    this.prefix = 'oubliette',
    this.keyAlias = 'default_key',
    required this.strongBox,
    required this.promptTitle,
    required this.promptSubtitle,
  }) : unlockedDeviceRequired = true,
       invalidatedByBiometricEnrollment = false;

  /// Requires biometric or device credential authentication for every
  /// encrypt/decrypt operation. The key is **permanently invalidated**
  /// if biometric enrollment changes — the secret becomes irrecoverable.
  ///
  /// Requires `<uses-permission android:name="android.permission.USE_BIOMETRIC" />`
  /// in your app's `AndroidManifest.xml`. Only effective on API 30+ (Android 11).
  const AndroidSecretAccess.biometricFatal({
    this.prefix = 'oubliette',
    this.keyAlias = 'default_key',
    required this.strongBox,
    required this.promptTitle,
    required this.promptSubtitle,
  }) : unlockedDeviceRequired = true,
       invalidatedByBiometricEnrollment = true;

  const AndroidSecretAccess.custom({
    required this.prefix,
    required this.keyAlias,
    required this.strongBox,
    required this.unlockedDeviceRequired,
    required this.invalidatedByBiometricEnrollment,
    required this.promptTitle,
    required this.promptSubtitle,
  });

  /// Prefix prepended to every storage key.
  final String prefix;

  /// Android Keystore alias used for the AES-256-GCM encryption key.
  final String keyAlias;

  /// When `true`, prefers StrongBox-backed key storage if the device
  /// supports it (`PackageManager.FEATURE_STRONGBOX_KEYSTORE`).
  /// Falls back silently to TEE if StrongBox is unavailable.
  final bool strongBox;

  /// When `true`, the hardware-backed key can only be used while the
  /// device is unlocked.
  final bool unlockedDeviceRequired;

  /// Title displayed on the biometric prompt dialog.
  final String? promptTitle;

  /// Subtitle displayed on the biometric prompt dialog.
  final String? promptSubtitle;

  /// When `true`, the key is permanently invalidated if biometric
  /// enrollment changes.
  final bool invalidatedByBiometricEnrollment;

  /// Whether biometric authentication is required.
  bool get userAuthenticationRequired => promptTitle != null;
}
