import 'dart:io';
import 'dart:typed_data';

import 'package:oubliette/android_oubliette.dart' show AndroidOubliette;
import 'package:oubliette/android_secret_access.dart';
import 'package:oubliette/darwin_oubliette.dart' show DarwinOubliette;
import 'package:oubliette/darwin_secret_access.dart';

export 'android_secret_access.dart';
export 'darwin_secret_access.dart';
export 'oubliette_string_extension.dart';

abstract class Oubliette {
  factory Oubliette({
    required AndroidSecretAccess android,
    required DarwinSecretAccess darwin,
  }) {
    switch (Platform.operatingSystem) {
      case 'ios':
      case 'macos':
        return DarwinOubliette(access: darwin);
      case 'android':
        return AndroidOubliette(access: android);
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  Oubliette.internal();

  Future<void> store(String key, Uint8List value);
  Future<Uint8List?> fetch(String key);
  Future<void> trash(String key);
  Future<bool> exists(String key);
}
