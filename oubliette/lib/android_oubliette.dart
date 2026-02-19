import 'package:flutter/foundation.dart';
import 'package:keystore/keystore.dart';
import 'package:oubliette/oubliette.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidOubliette extends Oubliette {
  AndroidOubliette({required this.access}) : super.internal();

  final Keystore _keystore = Keystore();
  final AndroidSecretAccess access;

  String _storedKey(String key) => access.prefix + key;

  @override
  Future<void> init() async {
    final exists = await _keystore.containsAlias(access.keyAlias);
    if (exists) {
      debugPrint('[Oubliette] Android key already exists: ${access.keyAlias}');
    } else {
      await _keystore.generateKey(
        alias: access.keyAlias,
        unlockedDeviceRequired: access.unlockedDeviceRequired,
        strongBox: access.strongBox,
        userAuthenticationRequired: access.userAuthenticationRequired,
        invalidatedByBiometricEnrollment: access.invalidatedByBiometricEnrollment,
      );
      debugPrint('[Oubliette] Android key generated: ${access.keyAlias}');
    }
  }

  @override
  Future<void> store(String key, Uint8List value) async {
    if (await exists(key)) {
      throw StateError('A value already exists for key "$key". Call trash() first.');
    }
    final storedKey = _storedKey(key);
    final ep = await _keystore.encrypt(
      alias: access.keyAlias,
      plaintext: value,
      aad: storedKey,
      promptTitle: access.promptTitle,
      promptSubtitle: access.promptSubtitle,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storedKey, ep.toJson());
  }

  @override
  Future<Uint8List?> fetch(String key) async {
    final storedKey = _storedKey(key);
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(storedKey);
    if (payload == null) return null;
    final ep = EncryptedPayloadMapper.fromJson(payload);
    return _keystore.decrypt(
      version: ep.version,
      alias: ep.keyAlias,
      ciphertext: ep.ciphertext,
      nonce: ep.nonce,
      aad: ep.aad,
      promptTitle: access.promptTitle,
      promptSubtitle: access.promptSubtitle,
    );
  }

  @override
  Future<void> trash(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storedKey(key));
  }

  @override
  Future<bool> exists(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storedKey(key));
  }
}
