import 'dart:typed_data';

import 'package:secure_storage/android_keystore/encrypted_payload.dart';
import 'package:secure_storage/android_keystore/keystore_facade.dart';
import 'package:secure_storage/secure_storage_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidSecureStorage extends SecureStorage {
  static const String _defaultKeyAlias = 'secure_storage_default';

  final KeystoreFacade _keystore = KeystoreFacade();
  final String keyAlias;

  AndroidSecureStorage({this.keyAlias = _defaultKeyAlias}) : super.internal();

  @override
  Future<void> store(String key, Uint8List value) async {
    final exists = await _keystore.containsAlias(keyAlias);
    if (!exists) {
      await _keystore.generateKey(
        alias: keyAlias,
        unlockedDeviceRequired: false,
      );
    }
    final ep = await _keystore.encrypt(
      alias: keyAlias,
      plaintext: value,
      aad: key,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, ep.toJson());
  }

  @override
  Future<Uint8List?> fetch(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(key);
    if (payload == null) return null;
    final ep = EncryptedPayloadMapper.fromJson(payload);
    return _keystore.decrypt(
      alias: keyAlias,
      ciphertext: ep.ciphertext,
      nonce: ep.nonce,
      aad: key,
    );
  }

  @override
  Future<void> trash(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<bool> exists(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}
