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
            const Duration(seconds: 5), onTimeout: () {
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
      "type" : VerificationType.mail.index
    }).timeout(const Duration(seconds: 5), onTimeout: () {
      return SocketData.fromFullData(
          {"success": false, "message_id": "", "message_type": "", "data": {}});
    });

    if (!res.isSuccess) {
      status.value = VerificationStatus.creationFail;
      return;
    } else {
      status.value = VerificationStatus.values[res.data?["status"] ?? 4];

      StreamController<Duration> _controller = StreamController();
      Stream<Duration>? stream;
      stream = Stream.periodic(Duration(seconds: 1), (d) {
        if (d >= duration.value.inSeconds) {
          status.value = VerificationStatus.timeout;
          _controller.done;
          return Duration.zero;
        }

        _controller.add(Duration(seconds: duration.value.inSeconds - d));
        return Duration(seconds: duration.value.inSeconds - d);
      });

      var subs = _controller.stream.listen((event) {
        _controller.add(event);
        duration.value = event;
      });

      await _controller.stream.last;
      stream = null;
      _controller.close();
      subs.cancel();
    }

    if (status.value == VerificationStatus.noOther) {
      return;
    }
    return;
  }
}
