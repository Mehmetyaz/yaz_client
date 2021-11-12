import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:yaz_client/src/services/encryption.dart';
import 'package:yaz_client/src/statics/statics.dart';

import '../../socket_service.dart';

class SocketData {
  ///
  SocketData();

  ///
  SocketData.create(
      {required Map<String, dynamic> data,
      this.messageId,
      required this.type}) {
    messageId ??= Statics.getRandomId(30);
    fullData = {"message_id": messageId, "message_type": type, "data": data};
    isDecrypted = true;
    isEncrypted = false;
  }

  ///
  factory SocketData.fromJson(Map<String, dynamic> data) =>
      SocketData.fromFullData(data);

  ///
  SocketData.fromFullData(this.fullData) {
    schemeValid = fullData!.containsKey("data") &&
        fullData!.containsKey("message_id") &&
        fullData!.containsKey("message_type");

    if (!schemeValid) {
      throw Exception("Socket Data Scheme isn't valid \n"
          "\"data\" is ${fullData!.containsKey("data")}\n"
          "\"message_id\" is ${fullData!.containsKey("message_id")}\n"
          "\"message_type\" is ${fullData!.containsKey("message_type")}");
    }

    messageId = fullData!["message_id"];
    type = fullData!["message_type"];

    isEncrypted =
        fullData!["data"] is String && fullData!["data"].startsWith("enc");
    if (isEncrypted) {
      fullData!["data"] = fullData!["data"].replaceFirst("enc", "");
    }
    isDecrypted = !isEncrypted;
  }

  ///
  factory SocketData.fromSocket(
    String rawData,
  ) {
    return SocketData.fromFullData(json.decode(rawData));
  }

  ///
  Map<String, dynamic>? toJson() => fullData;

  ///
  @JsonKey(name: "message_id", ignore: false, )
  String? messageId;

  ///
  @JsonKey(name: "message_type", ignore: false, )
  String? type;

  ///
  @JsonKey(ignore: true)
  late bool schemeValid;

  ///
  bool get isSuccess {
    try{
      return fullData!["success"];
    } on Exception {
      return false;
    }
  }

  ///
  Map<String, dynamic>? get data {
    if (isEncrypted || fullData!["data"] is String) {
      return {"success": false, "reason": "Data is encrypted"};
    }
    return fullData!["data"];
  }

  ///
  @JsonKey(ignore: true)
  Map<String, dynamic>? fullData = {
    "success": false,
    "reason": "data not created or operated"
  };

  ///
  @JsonKey(ignore: true)
  late bool isDecrypted;

  ///
  @JsonKey(ignore: true)
  late bool isEncrypted;

  ///
  Future<void> encrypt() async {
    Nonce? nonce = socketService.options.nonce, cNonce = socketService.options.cNonce;
    if (isDecrypted) {
      schemeValid = fullData!.containsKey("data") &&
          fullData!.containsKey("message_id") &&
          fullData!.containsKey("message_type");

      if (!schemeValid) {
        throw Exception("Socket Data Scheme isn't valid \n"
            "\"data\" is ${fullData!.containsKey("data")}\n"
            "\"message_id\" is ${fullData!.containsKey("message_id")}\n"
            "\"message_type\" is ${fullData!.containsKey("message_type")}");
      }

      messageId = fullData!["message_id"];
      type = fullData!["message_type"];
      fullData!["data"] =
          // ignore: lines_longer_than_80_chars
          "enc${await encryptionService.encrypt1(nonce: nonce!, cnonce: cNonce!, data: fullData!['data'])}";
      isEncrypted = true;
      isDecrypted = false;
    }
  }

  ///
  Future<void> decrypt() async {
    Nonce? nonce = socketService.options.nonce, cNonce = socketService.options.cNonce;

    if (isEncrypted ||
        (fullData!["data"] is String && fullData!["data"].startWith("enc"))) {
      fullData!["data"] = await encryptionService.decrypt1(
          nonce: nonce!, cnonce: cNonce!, data: fullData!['data']);
    }
    isEncrypted = false;
    isDecrypted = true;
  }



  dynamic operator[] (String key) => data![key];

}
