import 'dart:async';

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
    print("SERVER STAT 5: ${status.value}");
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
    if (res.isSuccess && res.data!["verified"]) {
      onVerify();
      timer?.cancel();
      timer = null;
      return true;
    }
    return false;
  }

  ///
  Future<void> resend() async {
    return _sendServer();
  }


  Timer? timer;

  ///
  Future<void> _sendServer() async {
    print("SERVER STAT 4: ${status.value}");
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
    print("SERVER STAT 3: ${status.value}");
    if (!res.isSuccess) {
      print("SERVER STAT 2: ${status.value}");
      status.value = VerificationStatus.creationFail;
      return;
    } else {
      status.value = VerificationStatus.values[res.data?["status"] ?? 4];

      print("SERVER STAT: ${status.value}");

      var completer = Completer();
      var i = 0;
       timer = Timer.periodic(Duration(seconds: 1), (t) {
        duration.value = Duration(seconds: 60 - (i));
        print("duration: ${duration.value}");
        if (i == 60) {
          completer.complete();
        }
        i++;
      });

      await completer.future;

      timer?.cancel();
      timer = null;
    }

    if (status.value == VerificationStatus.noOther) {
      return;
    }
    return;
  }
}
