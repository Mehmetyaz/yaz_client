import 'dart:convert' show base64, json, utf8;
import 'dart:typed_data' show Uint8List;

import 'package:cryptography/cryptography.dart'
    show Nonce, SecretKey, chacha20Poly1305Aead;
import 'package:flutter/material.dart';

///
class NoSecretKeyException implements Exception {
  @override
  String toString() => "Secret Key Not Found, Please init encryption service";
}

///
final EncryptionService encryptionService = EncryptionService();

///Crypto Service
class EncryptionService {
  ///
  factory EncryptionService() => _instance;

  EncryptionService._internal();

  static final EncryptionService _instance = EncryptionService._internal();

  ///Kriptolama 2 si clien 2 si serverda olmak üzere 4 adımda yapılıyor.
  ///Server 4'ünü de biliyor
  ///client sadece 2 sini

  ///kodlar kriptolanıyor, fakat içinden string ler
  /// ayıklanabilme şansı daha yüksek
  ///o yüzden string olarak yazmadım.
  SecretKey __secretKey1;

  SecretKey __secretKey2;

  ///
  void init(String key1, String key2) {
    __secretKey1 = SecretKey(key1.codeUnits);
    __secretKey2 = SecretKey(key2.codeUnits);
  }

  Future<Uint8List> _enc1Stage1(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: __secretKey1,
      nonce: nonce,
      aad: [12, 12, 10],
    );
    return encrypted;
  }

  Future<Uint8List> _enc1Stage2(Nonce cnonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: __secretKey2,
      nonce: cnonce,
      aad: [12, 12, 10],
    );
    return encrypted;
  }

  ///
  Future<String> encrypt1(
      {@required Nonce cnonce,
      @required Nonce nonce,
      @required Map<String, dynamic> data}) async {
    var _data = utf8.encode(json.encode(data));
    return base64
        .encode(await _enc1Stage2(cnonce, await _enc1Stage1(nonce, _data)));
  }

  Future<Uint8List> _dec1Stage1(Nonce cnonce, Uint8List encryptedData) async {
    final cipher = chacha20Poly1305Aead;

    chacha20Poly1305Aead.newSecretKeySync();

    /// Choose some 256-bit secret key
    final message = encryptedData;
    final encrypted = await cipher.decrypt(message,
        secretKey: __secretKey2, nonce: cnonce, aad: [12, 12, 10]);
    return encrypted;
  }

  Future<Uint8List> _dec1Stage2(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final message = data;
    final encrypted = await cipher.decrypt(message,
        secretKey: __secretKey1, nonce: nonce, aad: [12, 12, 10]);

    return encrypted;
  }

  ///
  Future<Map<String, dynamic>> decrypt1(
      {@required Nonce nonce,
      @required Nonce cnonce,
      @required String base64Data}) async {
    return json.decode(utf8.decode(await _dec1Stage2(
        nonce, await _dec1Stage1(cnonce, base64.decode(base64Data)))));
  }
}
