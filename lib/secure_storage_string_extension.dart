import 'dart:convert';
import 'dart:typed_data';

import 'package:secure_storage/secure_storage_interface.dart';

extension SecureStorageStringExtension on SecureStorage {
  Future<void> storeString(String key, String value) =>
      store(key, Uint8List.fromList(utf8.encode(value)));

  Future<String?> fetchString(String key) async {
    final bytes = await fetch(key);
    return bytes != null ? utf8.decode(bytes) : null;
  }
}
