import 'dart:async';
import 'dart:convert';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:yaz_client/src/services/web_socket_abstract.dart';

import 'exceptions/expected_arguments_web_socket.dart';

WebSocketServiceBase socketServiceInternal = WebSocketServiceWeb();

///Web Socket Servisi
class WebSocketServiceWeb extends WebSocketServiceBase {
  ///Default Constructor
  factory WebSocketServiceWeb() => _instance;

  ///singleton class
  WebSocketServiceWeb._internal();

  static final WebSocketServiceWeb _instance = WebSocketServiceWeb._internal();

  WebSocket? socket;

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
        socket = WebSocket(
            "ws://${options.globalHostName}:${options.webSocketPort}/ws");
        connected = false;
        return await connect(i++);
      } else if (socket?.readyState == 1) {
        //TODO: CLose on app close
        try {
          window.onBeforeUnload.listen((event) async {
            close();
          });

          socket?.onMessage.listen((event) {
            var d = json.decode(event.data);
            // ignore: avoid_print
            // print("SOCKET LISTEN EVENT : $event  "
            //     "\n   ready: ${socket?.readyState}");
            if (d.runtimeType != List && d["data"] != null) {
              // print(
              //     "ON OPEN::::"
              //         "${base64.encode
              //         (TypeCasts.uint8Cast(d["data"] ?? []))}");
            }
            options.streamController.sink.add(event.data);
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
          options.downloadBytes += ((event.length * 2) as int?)!;
          // ignore: avoid_print

          var dat = json.decode(event);

          if (dat['type'] != null && dat['type'] == 'connection_confirmation') {
            dat['device_id'] = options.deviceID;
            sendMessage(json.encode(dat));
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
    socket!.close();
  }

  @override
  void sendMessage(String data) {
    socket?.send(data);
  }
}
