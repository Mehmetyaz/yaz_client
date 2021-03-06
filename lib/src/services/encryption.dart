import 'dart:convert' show base64, json, utf8;
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:cryptography/cryptography.dart';

///
class NoSecretKeyException implements Exception {
  @override
  String toString() => "Secret Key Not Found, Please init encryption service";
}

///
class Nonce {
  ///
  Nonce(List<int> bytes) : _list = bytes;

  ///
  Nonce.random() : _list = _random;

  static List<int> get _random {
    var res = Uint8List(12);
    for (var i = 0; i < res.length; i++) {
      res[i] = Random().nextInt(255);
    }
    return res;
  }

  ///
  final List<int> _list;

  ///
  List<int> get list => _list;
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
  late SecretKey __secretKey1;

  late SecretKey __secretKey2;

  ///
  void init(String key1, String key2) {
    __secretKey1 = SecretKey(key1.codeUnits);
    __secretKey2 = SecretKey(key2.codeUnits);
  }

  ///
  Uint8List mergeMac(SecretBox secretBox) {
    return Uint8List.fromList(
        []..addAll(secretBox.mac.bytes)..addAll(secretBox.cipherText));
  }

  ///
  SecretBox splitMac(List<int> nonce, Uint8List list) {
    return SecretBox(list.sublist(16),
        nonce: nonce, mac: Mac(list.sublist(0, 16)));
  }

  ///1
  Chacha20 get chacha20Poly1305Aead => Chacha20.poly1305Aead();

  Future<Uint8List> _enc1Stage1(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    /// Choose some 256-bit secret key
    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: __secretKey1,
      nonce: nonce.list,
      aad: [12, 12, 10],
    );
    return mergeMac(encrypted);
  }

  Future<Uint8List> _enc1Stage2(Nonce cnonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;

    final message = data;
    final encrypted = await cipher.encrypt(
      message,
      secretKey: __secretKey2,
      nonce: cnonce.list,
      aad: [12, 12, 10],
    );

    return mergeMac(encrypted);
  }

  ///Encrypt 1
  Future<String> encrypt1(
      {required Nonce cnonce,
      required Nonce nonce,
      required Map<String, dynamic> data}) async {
    Uint8List _data = utf8.encode(json.encode(data)) as Uint8List;
    return base64
        .encode(await _enc1Stage2(cnonce, await _enc1Stage1(nonce, _data)));
  }

  Future<Uint8List> _dec1Stage1(Nonce cnonce, Uint8List encryptedData) async {
    final cipher = chacha20Poly1305Aead;

    var message = splitMac(cnonce.list, encryptedData);

    final encrypted = await cipher
        .decrypt(message, secretKey: __secretKey2, aad: [12, 12, 10]);
    return encrypted as Uint8List;
  }

  Future<Uint8List> _dec1Stage2(Nonce nonce, Uint8List data) async {
    final cipher = chacha20Poly1305Aead;



    final message = splitMac(nonce.list, data);

    final encrypted = await cipher.decrypt(message,
        secretKey: __secretKey1 /*, nonce: nonce*/, aad: [12, 12, 10]);

    return encrypted as Uint8List;
  }

  ///Decrypt 2
  Future<Map<String, dynamic>> decrypt1(
      {required Nonce nonce,
      required Nonce cnonce,
      required String data}) async {
    return json.decode(utf8.decode(await _dec1Stage2(
        nonce, await _dec1Stage1(cnonce, base64.decode(data)))));
  }
}
