import 'dart:async';

import 'package:yaz/yaz.dart';
import 'package:yaz_client/yaz_client.dart';

///
enum VerificationStatus {
  ///
  verified,

  ///
  waiting,

  ///
  timeout,

  ///
  fail,

  ///
  creationFail,

  ///
  creating,

  ///
  noOther,

  ///
  cancel
}

enum VerificationType { mail, phone, device }

///
class VerificationSession {
  ///
  VerificationSession.create(
      {Duration duration = const Duration(seconds: 60),
      required this.topic,
      required this.onVerify,
      required this.type,
      required this.receivePort})
      : status = VerificationStatus.creating.notifier,
        id = Statics.getRandomId(20),
        duration = duration.notifier {
    _sendServer();
  }

  ///
  String id;

  ///
  String topic;

  ///
  VerificationType type;

  ///
  String receivePort;

  ///
  YazNotifier<Duration> duration;

  ///
  YazNotifier<VerificationStatus> status;

  Future<void> Function() onVerify;

  Future<bool> verify(String code) async {
    var res = await socketService
        .customOperation("verification_code", {"id": id, "code": code}).timeout(
            const Duration(seconds: 15), onTimeout: () {
      return SocketData.fromFullData(
          {"success": false, "message_id": "", "message_type": "", "data": {}});
    });
    print("VERIF RES: ${res.fullData}");
    if (res.isSuccess && res.data!["verified"]) {
      onVerify();
      return true;
    }
    return false;
  }

  ///
  Future<void> resend() async {
    return _sendServer();
  }

  ///
  Future<void> _sendServer() async {
    var res = await socketService.customOperation("verification_request", {
      "topic": topic,
      "duration": duration.value.inMilliseconds,
      "id": id,
      "mail": receivePort,
      "type": VerificationType.mail.index
    }).timeout(const Duration(seconds: 5), onTimeout: () {
      return SocketData.fromFullData(
          {"success": false, "message_id": "", "message_type": "", "data": {}});
    });

    print("IF ONCESI: $res");

    print("IF ONCESI 2: ${res.fullData}");
    if (!res.isSuccess) {
      print("Verification  Creation Fail : ${res.fullData}");
      status.value = VerificationStatus.creationFail;
      return;
    } else {
      status.value = VerificationStatus.values[res.data?["status"] ?? 4];

      var completer = Completer();
      var i = 0;
      Timer? timer = Timer(Duration(seconds: 1), () {
        duration.value = Duration(seconds: 60 - (i));
        if (i == 60) {
          completer.complete();
        }
        i++;
      });

      await completer.future;

      timer.cancel();
      timer = null;
    }

    if (status.value == VerificationStatus.noOther) {
      return;
    }
    return;
  }
}
