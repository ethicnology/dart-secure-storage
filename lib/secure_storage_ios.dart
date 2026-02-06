import 'dart:typed_data';

import 'package:secure_storage/ios_keychain/keychain_facade.dart';
import 'package:secure_storage/secure_storage_interface.dart';

class IosSecureStorage extends SecureStorage {
  IosSecureStorage() : super.internal();

  final KeychainFacade _keychain = KeychainFacade();

  @override
  Future<void> store(String key, Uint8List value) async {
    await _keychain.secItemAdd(key, value);
  }

  @override
  Future<Uint8List?> fetch(String key) async {
    return _keychain.secItemCopyMatching(key);
  }

  @override
  Future<void> trash(String key) async {
    await _keychain.secItemDelete(key);
  }

  @override
  Future<bool> exists(String key) async {
    return _keychain.contains(key);
  }
}
