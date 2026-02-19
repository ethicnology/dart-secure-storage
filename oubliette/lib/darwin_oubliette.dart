import 'package:flutter/foundation.dart';
import 'package:keychain/keychain.dart';
import 'package:oubliette/oubliette.dart';

class DarwinOubliette extends Oubliette {
  DarwinOubliette({required this.access})
      : _keychain = Keychain(config: access.toConfig()),
        super.internal();

  final DarwinSecretAccess access;
  final Keychain _keychain;

  String _storedKey(String key) => access.prefix + key;

  @override
  Future<void> init() async {
    if (!access.secureEnclave) return;
    final existed = await _keychain.ensureEnclaveKeyPair();
    if (existed) {
      debugPrint('[Oubliette] Darwin SE key already exists (service: ${access.service})');
    } else {
      debugPrint('[Oubliette] Darwin SE key generated (service: ${access.service})');
    }
  }

  @override
  Future<void> store(String key, Uint8List value) async {
    if (await exists(key)) {
      throw StateError('A value already exists for key "$key". Call trash() first.');
    }
    await _keychain.secItemAdd(_storedKey(key), value);
  }

  @override
  Future<Uint8List?> fetch(String key) async {
    return _keychain.secItemCopyMatching(_storedKey(key));
  }

  @override
  Future<void> trash(String key) async {
    await _keychain.secItemDelete(_storedKey(key));
  }

  @override
  Future<bool> exists(String key) async {
    return _keychain.contains(_storedKey(key));
  }
}
