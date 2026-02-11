import 'package:keychain/keychain.dart';

/// Darwin (iOS / macOS) options backed by the Keychain.
///
/// Use [DarwinOptions.iOS] for iOS. Use [DarwinOptions.macOS] to
/// expose macOS-specific fields like [useDataProtection].
class DarwinOptions {
  const DarwinOptions.iOS({
    this.prefix = 'oubliette',
    this.service,
    this.unlockedDeviceRequired = true,
    this.authentication,
  }) : useDataProtection = false;

  /// macOS constructor — exposes [useDataProtection] which enables
  /// `kSecUseDataProtectionKeychain` on macOS 10.15+, using the iOS-style
  /// data protection keychain instead of the legacy file-based keychain.
  /// Requires the `keychain-access-groups` entitlement and a valid
  /// code-signing identity. Ignored on iOS.
  const DarwinOptions.macOS({
    this.prefix = 'oubliette',
    this.service,
    this.unlockedDeviceRequired = true,
    this.authentication,
    this.useDataProtection = false,
  });

  /// Prefix prepended to every storage key in the Keychain.
  final String prefix;

  /// `kSecAttrService` — namespaces keychain items so the same key in
  /// different services won't collide.
  final String? service;

  /// When `true`, items use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  /// (class key is wiped from memory on lock). When `false`, items use
  /// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (class key persists
  /// in memory until reboot).
  final bool unlockedDeviceRequired;

  /// When non-null, keychain items require biometric or passcode
  /// authentication to be read. On macOS this implicitly enables
  /// `kSecUseDataProtectionKeychain`.
  final DarwinAuthentication? authentication;

  /// macOS only — opts into the data protection keychain.
  /// No effect on iOS.
  final bool useDataProtection;

  KeychainConfig toConfig() => KeychainConfig(
    service: service,
    accessibility: authentication != null
        ? KeychainAccessibility.whenPasscodeSetThisDeviceOnly
        : (unlockedDeviceRequired
              ? KeychainAccessibility.whenUnlockedThisDeviceOnly
              : KeychainAccessibility.afterFirstUnlockThisDeviceOnly),
    useDataProtection: useDataProtection || authentication != null,
    authenticationRequired: authentication != null,
    biometryCurrentSetOnly: authentication?.biometryCurrentSetOnly ?? false,
    authenticationPrompt: authentication?.promptReason,
  );
}

/// When provided to [DarwinOptions], keychain items are
/// stored with `SecAccessControlCreateWithFlags` using `.userPresence`
/// (or `.biometryCurrentSet` when [biometryCurrentSetOnly] is `true`).
///
/// Authentication behavior per operation (Apple Keychain API design):
/// - **fetch** (`SecItemCopyMatching`): triggers biometry / passcode prompt.
/// - **store** (new item via `SecItemAdd`): no prompt.
/// - **update** (existing item via `SecItemUpdate`): may prompt if the
///   item already carries access control.
/// - **delete** (`SecItemDelete`): never prompts — data is destroyed,
///   not read.
///
/// The [promptReason] is passed as `kSecUseOperationPrompt` on read
/// operations so the system shows a reason string in the dialog.
///
/// On macOS this triggers Touch ID (or the account password on Macs
/// without Touch ID). Requires `kSecUseDataProtectionKeychain` which
/// in turn requires a valid code-signing identity and the
/// `keychain-access-groups` entitlement.
class DarwinAuthentication {
  const DarwinAuthentication({
    required this.promptReason,
    this.biometryCurrentSetOnly = false,
  });

  /// Reason displayed in the system authentication dialog when reading.
  final String promptReason;

  /// When `true`, uses `.biometryCurrentSet` instead of `.userPresence`,
  /// which invalidates items when biometric enrollment changes (e.g. new
  /// fingerprint added). Passcode fallback is not available in this mode.
  final bool biometryCurrentSetOnly;
}
