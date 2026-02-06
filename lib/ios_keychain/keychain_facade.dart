import 'package:flutter/services.dart';

/// Keychain item accessibility; maps to kSecAttrAccessible (when the item can be read).
enum KeychainAccessibility {
  whenUnlocked('whenUnlocked'),
  whenUnlockedThisDeviceOnly('whenUnlockedThisDeviceOnly'),
  afterFirstUnlock('afterFirstUnlock'),
  afterFirstUnlockThisDeviceOnly('afterFirstUnlockThisDeviceOnly'),
  whenPasscodeSetThisDeviceOnly('whenPasscodeSetThisDeviceOnly');

  final String _value;
  const KeychainAccessibility(this._value);
  String get value => _value;
}

class KeychainFacade {
  final MethodChannel _channel = const MethodChannel('secure_storage');

  /// Returns whether a keychain item exists for [alias] without reading its data
  /// (SecItemCopyMatching with kSecReturnData: false).
  /// Throws [PlatformException] if the platform returns null (indicates an error).
  Future<bool> contains(String alias) async {
    final result = await _channel.invokeMethod<bool>('keychainContains', {
      'alias': alias,
    });
    if (result != null) return result;

    throw PlatformException(
      code: 'keychain_contains_failed',
      message: 'Native keychain contains returned null.',
    );
  }

  /// Adds or updates a keychain item (SecItemAdd / SecItemUpdate). Stores [data]
  /// under [alias] as a generic password. [accessibility] maps to kSecAttrAccessible.
  ///
  /// See: https://developer.apple.com/documentation/security/secitemadd(_:_:)
  /// See: https://developer.apple.com/documentation/security/secitemupdate(_:_:)
  Future<void> secItemAdd(
    String alias,
    Uint8List data, {
    KeychainAccessibility accessibility =
        KeychainAccessibility.whenUnlockedThisDeviceOnly,
  }) async {
    await _channel.invokeMethod<void>('secItemAdd', {
      'alias': alias,
      'data': data,
      'accessibility': accessibility.value,
    });
  }

  /// Copies the first keychain item matching [alias] (SecItemCopyMatching).
  /// Returns the item's secret data or null if not found.
  ///
  /// See: https://developer.apple.com/documentation/security/secitemcopymatching(_:_:)
  Future<Uint8List?> secItemCopyMatching(String alias) async {
    final result = await _channel.invokeMethod<Uint8List?>(
      'secItemCopyMatching',
      {'alias': alias},
    );
    return result;
  }

  /// Deletes the keychain item for [alias] (SecItemDelete).
  ///
  /// See: https://developer.apple.com/documentation/security/secitemdelete(_:)
  Future<void> secItemDelete(String alias) async {
    await _channel.invokeMethod<void>('secItemDelete', {'alias': alias});
  }
}
