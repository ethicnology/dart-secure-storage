import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

part 'encrypted_payload.mapper.dart';

class Uint8ListBase64Hook extends MappingHook {
  const Uint8ListBase64Hook();

  @override
  Object? beforeEncode(Object? value) {
    if (value is Uint8List) return base64Encode(value);
    return value;
  }

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) return Uint8List.fromList(base64Decode(value));
    return value;
  }
}

@MappableClass()
class EncryptedPayload with EncryptedPayloadMappable {
  @MappableField(hook: Uint8ListBase64Hook())
  final Uint8List nonce;

  @MappableField(hook: Uint8ListBase64Hook())
  final Uint8List ciphertext;

  const EncryptedPayload({required this.nonce, required this.ciphertext});
}
