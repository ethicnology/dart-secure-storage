import 'package:keychain/keychain.dart';

export 'package:keychain/keychain.dart' show KeychainAccessibility;

/// Controls how secrets are protected on iOS and macOS (Darwin).
///
/// Use one of the named constructors to select a security profile:
/// - [DarwinSecretAccess.evenLocked] — accessible even when the device is locked (after first unlock since boot).
/// - [DarwinSecretAccess.onlyUnlocked] — accessible only while the device is unlocked.
/// - [DarwinSecretAccess.biometric] — requires biometric/passcode auth; survives biometric enrollment changes.
/// - [DarwinSecretAccess.biometricStrict] — requires biometric auth; invalidated if biometric enrollment changes. No passcode fallback.
///
/// ### macOS keychain backends
///
/// On macOS there are two keychain backends:
///
/// - **Legacy file-based keychain** (default when [useDataProtection] is `false`):
///   Works without code signing or entitlements. When [authenticationRequired]
///   is `true`, the system prompts for the user's macOS login password on
///   every read via `SecAccessControl` with `.userPresence`. No Touch ID
///   support on this backend.
///
/// - **Data Protection keychain** (when [useDataProtection] is `true`):
///   iOS-style keychain on macOS 10.15+. Supports Touch ID and biometric
///   policies via `SecAccessControl`. **Requires** the app to be code-signed
///   with a Development Certificate and the `keychain-access-groups`
///   entitlement — without this you get `errSecMissingEntitlement` (-34018).
///
/// The [biometric] and [biometricStrict] profiles set [useDataProtection]
/// to `true` because they rely on Touch ID / Face ID which is only available
/// through the Data Protection keychain. If you only need a macOS password
/// prompt (no biometric), use [DarwinSecretAccess.custom] with
/// `authenticationRequired: true` and `useDataProtection: false`.
class DarwinSecretAccess {
  /// Accessible after the first unlock since boot, even when the device
  /// is locked. Maps to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
  const DarwinSecretAccess.evenLocked({this.prefix = 'oubliette', this.service})
    : accessibility = KeychainAccessibility.afterFirstUnlockThisDeviceOnly,
      useDataProtection = false,
      authenticationRequired = true,
      biometryCurrentSetOnly = false,
      authenticationPrompt = null;

  /// Accessible only while the device is unlocked. The class key is
  /// wiped from memory on lock. Maps to
  /// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
  const DarwinSecretAccess.onlyUnlocked({
    this.prefix = 'oubliette',
    this.service,
  }) : accessibility = KeychainAccessibility.whenUnlockedThisDeviceOnly,
       useDataProtection = false,
       authenticationRequired = false,
       biometryCurrentSetOnly = false,
       authenticationPrompt = null;

  /// Requires biometric or passcode authentication on every read.
  /// Survives biometric enrollment changes (e.g. new fingerprint).
  ///
  /// Sets [useDataProtection] to `true`. On macOS this uses the Data
  /// Protection keychain which requires code signing and entitlements.
  /// For a password-only prompt on unsigned macOS apps, use
  /// [DarwinSecretAccess.custom] with `useDataProtection: false`.
  const DarwinSecretAccess.biometric({
    this.prefix = 'oubliette',
    this.service,
    required String promptReason,
  }) : accessibility = KeychainAccessibility.whenUnlockedThisDeviceOnly,
       useDataProtection = true,
       authenticationRequired = true,
       biometryCurrentSetOnly = false,
       authenticationPrompt = promptReason;

  /// Requires biometric authentication on every read. The item is
  /// **invalidated** if biometric enrollment changes — the secret
  /// becomes irrecoverable. No passcode fallback.
  ///
  /// Sets [useDataProtection] to `true`. On macOS this uses the Data
  /// Protection keychain which requires code signing and entitlements.
  const DarwinSecretAccess.biometricStrict({
    this.prefix = 'oubliette',
    this.service,
    required String promptReason,
  }) : accessibility = KeychainAccessibility.whenUnlockedThisDeviceOnly,
       useDataProtection = true,
       authenticationRequired = true,
       biometryCurrentSetOnly = true,
       authenticationPrompt = promptReason;

  /// Full control over every keychain parameter.
  ///
  /// Useful for advanced combinations such as password-only prompts on
  /// unsigned macOS apps (`authenticationRequired: true`,
  /// `useDataProtection: false`).
  const DarwinSecretAccess.custom({
    required this.prefix,
    required this.service,
    required this.accessibility,
    required this.useDataProtection,
    required this.authenticationRequired,
    required this.biometryCurrentSetOnly,
    required this.authenticationPrompt,
  });

  /// Prefix prepended to every storage key in the Keychain.
  final String prefix;

  /// `kSecAttrService` — namespaces keychain items so the same key in
  /// different services won't collide.
  final String? service;

  /// `kSecAttrAccessible` value controlling when the item is readable.
  final KeychainAccessibility accessibility;

  /// On macOS, switches to the iOS-style Data Protection keychain
  /// (`kSecUseDataProtectionKeychain`). Requires code signing and the
  /// `keychain-access-groups` entitlement. Ignored on iOS (always active).
  final bool useDataProtection;

  /// When `true`, a `SecAccessControl` is attached to the item requiring
  /// user authentication (biometric or password) on every read.
  /// On macOS with [useDataProtection] `false`, this triggers the legacy
  /// keychain password prompt. With [useDataProtection] `true`, it enables
  /// Touch ID / Face ID via the Data Protection keychain.
  final bool authenticationRequired;

  /// When `true`, uses `.biometryCurrentSet` instead of `.userPresence`.
  /// The item is invalidated if biometric enrollment changes (e.g. a new
  /// fingerprint is added). No passcode fallback.
  final bool biometryCurrentSetOnly;

  /// Reason displayed in the system authentication dialog when reading.
  final String? authenticationPrompt;

  KeychainConfig toConfig() => KeychainConfig(
    service: service,
    accessibility: accessibility,
    useDataProtection: useDataProtection,
    authenticationRequired: authenticationRequired,
    biometryCurrentSetOnly: biometryCurrentSetOnly,
    authenticationPrompt: authenticationPrompt,
  );
}
