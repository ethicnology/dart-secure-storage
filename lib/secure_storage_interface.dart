import 'dart:typed_data';

abstract class SecureStorage {
  SecureStorage.internal();

  Future<void> store(String key, Uint8List value);
  Future<Uint8List?> fetch(String key);
  Future<void> trash(String key);
  Future<bool> exists(String key);
}
