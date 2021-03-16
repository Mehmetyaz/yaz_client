import 'dart:async';
import 'dart:convert';

import 'package:yaz_client/src/models/query_model/query_model.dart';
import 'package:yaz_client/src/models/socket_data/socket_data.dart';

import '../../yaz_client.dart';

class SocketDataListener extends Stream<SocketData> {
  SocketDataListener(this._query) : this._id = Statics.getRandomId(20);

  void close() {
    isActive = false;
    socketService.customOperation(
        "remove_stream", {"message_id": _id, "object_id": _objectId},
        useToken: false);
  }

  final QueryBuilder _query;

  final String _id;

  String? _objectId;

  bool isActive = false;

  /// If listen onData mounted but listener is deactivated,
  /// you can reactive, but DON'T listen again,
  /// because, listen() started query
  void reactive() {

    socketService.query(_query, customID: _id , stream: true).then((value) {
      _onData!(value);
      if (value.data!["_id"] != null) {
        _objectId = value.data!["_id"];
      }
    });
    isActive = true;
  }

  void Function(SocketData event)? _onData;

  @override
  StreamSubscription<SocketData> listen(void Function(SocketData event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _onData = onData;


    socketService.query(_query, customID: _id ,stream: true).then((value) {
      onData!(value);
      if (value.data!["_id"] != null) {
        _objectId = value.data!["_id"];
      }
    });

    isActive = true;
    return socketService.options.socketConnection.where((d) {
      try {
        var dat = json.decode(d);

        print(dat);

        if (dat["message_id"] == null || dat["message_type"] == null)
          return false;

        return dat["message_id"] == _id && dat["message_type"] == "streaming";
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
    socketService.sendMessage(json.encode(
        {"message_id": _id, "message_type": "stream_received", "data": {}}));
  }
}
