import 'dart:typed_data';

import 'package:keychain/keychain.dart';
import 'package:oubliette/oubliette.dart';

class DarwinOubliette extends Oubliette {
  DarwinOubliette({DarwinOptions? options})
      : options = options ?? const DarwinOptions.iOS(),
        _keychain = Keychain(
          config: (options ?? const DarwinOptions.iOS()).toConfig(),
        ),
        super.internal();

  final DarwinOptions options;
  final Keychain _keychain;

  String _storedKey(String key) => options.prefix + key;

  @override
  Future<void> store(String key, Uint8List value) async {
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
