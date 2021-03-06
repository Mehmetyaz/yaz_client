import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:yaz_client/src/services/web_socket_abstract.dart';

import 'exceptions/expected_arguments_web_socket.dart';

///
WebSocketServiceBase socketServiceInternal = WebSocketServiceMobile();

///Web Socket Servisi
class WebSocketServiceMobile extends WebSocketServiceBase {
  ///Default Constructor
  factory WebSocketServiceMobile() => _instance;

  ///singleton class
  WebSocketServiceMobile._internal();

  static final WebSocketServiceMobile _instance =
      WebSocketServiceMobile._internal();

  WebSocket socket;

  ///bağlantı
  Future<bool> connect([int i = 0]) async {
    if (options.globalHostName == null || options.webSocketPort == null) {
      throw MissingWebSocketArguments(
          hostIsNull: options.globalHostName == null,
          portIsNull: options.webSocketPort == null);
    }
    try {
      // ignore: avoid_print
      print('CONNECTION ${socket?.readyState ?? 'null'}');

      if (socket == null || socket?.readyState == 3) {
        socket = await WebSocket.connect(
            "ws://${options.globalHostName}:${options.webSocketPort}/ws");
        connected = false;
        return await connect(i++);
      } else if (socket?.readyState == 1) {
        //TODO: CLose on app close
        try {
          socket?.listen((event) {
            var d = json.decode(event);
            // ignore: avoid_print
            // print("SOCKET LISTEN EVENT : $event  "
            //     "\n   ready: ${socket?.readyState}");
            if (d.runtimeType != List && d["data"] != null) {
              // print(
              //     "ON OPEN::::"
              //         "${base64.encode
              //         (TypeCasts.uint8Cast(d["data"] ?? []))}");
            }
            options.streamController.sink.add(event);
          }, onError: (e) {
            // ignore: avoid_print
            print("ON ERROR::::$e");
            connected = false;
          }, onDone: () {
            connected = false;
          });
        } on Exception {
          socket = null;
          await connect(i++);
        }

        options.socketConnection.listen((event) {
          options.downloadBytes += (event.length * 2) as int;
          // ignore: avoid_print

          var dat = json.decode(event);

          if (dat['type'] != null && dat['type'] == 'connection_confirmation') {
            dat['device_id'] = options.deviceID;
            socket?.add(json.encode(dat));
          }
        });
        connected = true;
        return await requestConnection();
      } else {
        if (i < 6) {
          if (i == 0 || i == 1 || i == 2) {
            await Future.delayed(const Duration(seconds: 1));
          } else {
            await Future.delayed(const Duration(seconds: 3));
          }
          return connect(i++);
        } else {
          return false;
        }
      }
    } on Exception catch (e) {
      // ignore: avoid_print
      print(e);
      return false;
    }
  }

  @override
  closeSocket() {
    socket.close();
  }

  @override
  void sendMessage(String data) {
    socket.add(data);
  }
}
