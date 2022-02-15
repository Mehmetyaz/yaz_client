import 'dart:async';
import 'dart:convert';


import '../../yaz_client.dart';

class ChatDataListener extends Stream<SocketData> {


  factory ChatDataListener() => _ins;
  static final ChatDataListener _ins = ChatDataListener._();
  ChatDataListener._(){
    _id ??=  Statics.getRandomId(20);
  }



  void close() {
    isActive = false;
    socketService.customOperation(
        "remove_stream_chat", {},
        useToken: false);
  }


  String? _id;



  bool isActive = false;

  /// If listen onData mounted but listener is deactivated,
  /// you can reactive, but DON'T listen again,
  /// because, listen() started query
  void reactive() {
    socketService.customOperation("start_stream_chat", {});
    isActive = true;
  }


  @override
  StreamSubscription<SocketData> listen(void Function(SocketData event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    isActive = true;
    reactive();
    return socketService.options.socketConnection.where((d) {
      try {
        var dat = json.decode(d);



        if (dat["message_id"] == null || dat["message_type"] == null)
          return false;

        return dat["message_type"] == "stream_chat";
      } catch (e) {
        return false;
      }
    }).transform<SocketData>(StreamTransformer.fromBind((a) async* {
      await for (var d in a) {
        _sendReceived();
        var dat = SocketData.fromSocket(d);
        await dat.decrypt();
        yield dat;
      }
    })).listen(onData,
        cancelOnError: cancelOnError, onDone: onDone, onError: onError);
  }

  void _sendReceived() {
    socketService.sendMessage(json.encode({
      "message_id": _id,
      "message_type": "stream_chat_received",
      "data": {}
    }));
  }
}
