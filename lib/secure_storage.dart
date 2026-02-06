import 'dart:io';

import 'package:secure_storage/secure_storage_android.dart' show AndroidSecureStorage;
import 'package:secure_storage/secure_storage_interface.dart';
import 'package:secure_storage/secure_storage_ios.dart' show IosSecureStorage;

export 'secure_storage_interface.dart';
export 'secure_storage_string_extension.dart';

SecureStorage createSecureStorage({String keyAlias = 'secure_storage_default'}) {
  switch (Platform.operatingSystem) {
    case 'ios':
      return IosSecureStorage();
    case 'android':
      return AndroidSecureStorage(keyAlias: keyAlias);
    default:
      throw UnsupportedError('Unsupported platform');
  }
}
