import 'dart:io';
import 'dart:typed_data';

import 'package:oubliette/android_oubliette.dart' show AndroidOubliette;
import 'package:oubliette/android_options.dart';
import 'package:oubliette/darwin_oubliette.dart' show DarwinOubliette;
import 'package:oubliette/darwin_options.dart';

export 'android_options.dart';
export 'darwin_options.dart';
export 'oubliette_string_extension.dart';

abstract class Oubliette {
  Oubliette.internal();

  Future<void> store(String key, Uint8List value);
  Future<Uint8List?> fetch(String key);
  Future<void> trash(String key);
  Future<bool> exists(String key);
}

enum OubliettePlatform { ios, macos, android }

OubliettePlatform get _currentPlatform {
  switch (Platform.operatingSystem) {
    case 'ios':
      return OubliettePlatform.ios;
    case 'macos':
      return OubliettePlatform.macos;
    case 'android':
      return OubliettePlatform.android;
    default:
      throw UnsupportedError('Unsupported platform');
  }
}

Oubliette createOubliette({
  AndroidOptions? androidOptions,
  DarwinOptions? iosOptions,
  DarwinOptions? macosOptions,
}) {
  switch (_currentPlatform) {
    case OubliettePlatform.ios:
      return DarwinOubliette(options: iosOptions ?? const DarwinOptions.iOS());
    case OubliettePlatform.macos:
      return DarwinOubliette(options: macosOptions ?? const DarwinOptions.macOS());
    case OubliettePlatform.android:
      return AndroidOubliette(
        options: androidOptions ?? const AndroidOptions(),
      );
  }
}
