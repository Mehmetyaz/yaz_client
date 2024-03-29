import 'dart:async'
    show
        Future,
        Stream,
        StreamController,
        StreamSubscription,
        StreamTransformer;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaz_client/src/models/chat_data_listener.dart';
import 'package:yaz_client/src/models/stream_socket_data.dart';
import '../statics/query_type.dart';

import '../models/query_model/query_model.dart';
import '../models/socket_data/socket_data.dart';
import '../statics/statics.dart';
import 'auth_service.dart';
import 'encryption.dart';

class SocketServiceOptions {
  factory SocketServiceOptions() => _instance;

  SocketServiceOptions._internal();

  static final SocketServiceOptions _instance =
      SocketServiceOptions._internal();

  bool secure = false;

  ///Access token
  String? token;

  ///Unique random device ID
  String? deviceID;

  ///kriptolama ile ilgili bilgiler burada tutuluyor.
  ///Tüm bağlantılar buradan yönetiliyor
  Nonce? nonce, cNonce;

  ///Web socket posr
  String? webSocketPort;

  ///Media server port
  String? mediaServerPort;

  // String _ = '192.168.1.19';

/*  static final String _hostname = '192.168.1.19';*/

  ///Global host
  String? globalHostName;

  ///Stream socket connection
  ///Listening messages
  Stream<dynamic> get socketConnection => streamController.stream;
  final StreamController streamController = StreamController.broadcast();

  ///Bytes for session
  int downloadBytes = 0, uploadBytes = 0;

  void close() {
    streamController.close();
  }
}

///Web Socket Servisi
abstract class WebSocketServiceBase {
  SocketServiceOptions options = SocketServiceOptions();

  void init(String host, String webSocketPort, {bool secure = false}) {
    options.webSocketPort = webSocketPort;
    options.mediaServerPort = webSocketPort;
    options.globalHostName = host;
    options.secure = secure;
  }

  ///Web Socket connected
  bool connected = false;

  /// Only use for custom data listening
  Stream<SocketData> listenCustomMessage({String? id, String? type}) async* {
    await for (var d in options.socketConnection.where((event) {
      Map<String, dynamic> _d = json.decode(event);
      var _dType = _d['message_type'];
      var _dId = _d['message_id'];
      if (type != null && id != null) {
        return _dType == type && _dId == id;
      } else if (type == null && id != null) {
        return _dId == id;
      } else if (id == null && type != null) {
        return _dType == type;
      } else {
        return true;
      }
    }).transform(StreamTransformer.fromBind((fr) async* {
      await for (var socketDa in fr) {
        yield SocketData.fromSocket(socketDa);
      }
    }))) {
      yield d;
    }
  }

  ///Wait socket message
  ///Waiting message that [id] equals sent message [id]
  Future<SocketData> waitMessage({String? id, String? type}) async {
    if (connected) {
      var d =
          SocketData.fromSocket(await (options.socketConnection.where((event) {
        Map<String, dynamic> _d = json.decode(event);
        var _dType = _d['message_type'];
        var _dId = _d['message_id'];
        if (type != null && id != null) {
          return _dType == type && _dId == id;
        } else if (type == null && id != null) {
          return _dId == id;
        } else if (id == null && type != null) {
          return _dType == type;
        } else {
          return true;
        }
      }).first));

      await d.decrypt();
      return d;
    } else {
      return SocketData.fromFullData(
          {'success': false, 'reason': 'No connection'});
    }
  }

  ///Send data and wait response
  ///standart queryler için
  Future<SocketData> sendAndWaitMessage(SocketData data,
      {bool encrypted = true, int? trying}) async {
    trying ??= 0;
    if (connected) {
      try {
        if (encrypted) {
          await data.encrypt();

          var _sendingData = json.encode(data);
          var _sendingBytes = _sendingData.length * 2;
          options.uploadBytes += _sendingBytes;

          // ignore: avoid_print
          // print("SENDING DATA ON SEND AND WAIT DATA: $_sendingData");

          sendMessage(_sendingData);
          // print(
          //     'SENDING::::${_byteCountToString(_sendingBytes)} / ${_byteCountToString(_uploadBytes)}');
          var responseData = await waitMessage(id: data.messageId);

          await responseData.decrypt();
          return responseData;
        } else {
          var _sendingData = json.encode(data);
          var _sendingBytes = _sendingData.length * 2;
          options.uploadBytes += _sendingBytes;
          // ignore: avoid_print
          // print("SENDING DATA ON SEND AND WAIT DATA NOT ENC: $_sendingData \n"
          //     "${data.fullData}");
          sendMessage(_sendingData);

          var responseData = await waitMessage(id: data.messageId);
          await responseData.decrypt();
          return responseData;
        }
      } on Exception catch (e) {
        if (e.runtimeType == StateError) {
          connected = false;
        }
        throw Exception(e.toString());
      }
    } else {
      if (trying < 5) {
        await connect();
        return sendAndWaitMessage(data, encrypted: encrypted, trying: trying++);
      } else {
        return SocketData.fromFullData(
            {'reason': 'no_connection', 'success': false});
      }
    }
  }

  /// Sending data to server
  /// Data must be String utf8 encoded
  void sendMessage(String data);

  /// Update Document Data
  /// example for change user name for user that
  /// his mail address is  "mehmedyaz@gmail.com":
  ///
  /// updateDocument(QueryBuilder , UpdateData) ;
  ///
  /// ```
  /// var queryBuilder = collection("users")
  ///               .where("user_mail" , isEqualTo: "mehmedyaz@gmail.com");
  /// updateDocument( queryBuilder , {
  ///    "\$set" : {
  ///       "user_name" : "Mehmet"
  ///    }
  /// })
  /// ```
  ///
  /// Using mongo db update syntax
  /// https://docs.mongodb.com/manual/reference/method/db.collection.update/#db.collection.update
  Future<SocketData> updateDocument(
      QueryBuilder queryBuilder, Map<String, dynamic> update,
      {int trying = 0}) async {
    if (connected) {
      var query = queryBuilder.toQuery(QueryType.update, token: options.token);
      query.update = update;
      return sendAndWaitMessage(SocketData.create(
          data: <String, dynamic>{"query": query.toJson()}, type: "query"));
    } else {
      if (trying < 5) {
        await connect();
        return updateDocument(queryBuilder, update, trying: trying++);
      } else {
        return SocketData.fromFullData(
            {'success': false, "reason": "No Connection"});
      }
    }
  }

  Future<SocketData> customOperation(String name, Map<String, dynamic> args,
      {bool useToken = true}) {
    if (useToken) {
      args["token"] = options.token;
    }
    return sendAndWaitMessage(SocketData.create(data: args, type: name));
  }

  /// Query one document in a collection
  ///
  /// query(QueryBuilder)
  /// listenDocument(collection("my_col").[where].[filter].[sort].[limit].[offset])
  /// see [collection]  function document
  /// for learn that , How to create [QueryBuilder]
  /// return [Future<SocketData>]
  ///
  /// can check query success in [SocketData] instance member of [isSuccess]
  /// if query success can found document in [SocketData] instance member of [data]
  Future<int?> count(QueryBuilder _queryBuilder, {int trying = 0}) async {
    if (connected) {
      var _query = _queryBuilder.toQuery(QueryType.count, token: options.token);
      var res = await sendAndWaitMessage(SocketData.create(
          data: <String, dynamic>{'query': _query.toJson()}, type: "query"));
      if (res.isSuccess) {
        return res.data?["count"];
      }
    } else {
      if (trying < 5) {
        await connect();
        return count(_queryBuilder, trying: trying++);
      } else {
        return null;
      }
    }
    return null;
  }

  /// Query one document in a collection
  ///
  /// query(QueryBuilder)
  /// listenDocument(collection("my_col").[where].[filter].[sort].[limit].[offset])
  /// see [collection]  function document
  /// for learn that , How to create [QueryBuilder]
  /// return [Future<SocketData>]
  ///
  /// can check query success in [SocketData] instance member of [isSuccess]
  /// if query success can found document in [SocketData] instance member of [data]
  Future<SocketData> query(QueryBuilder _queryBuilder,
      {int trying = 0, String? customID, bool stream = false}) async {
    if (connected) {
      var _query = _queryBuilder.toQuery(
          stream ? QueryType.streamQuery : QueryType.query,
          token: options.token);
      return sendAndWaitMessage(SocketData.create(
          data: <String, dynamic>{'query': _query.toJson()},
          type: "query",
          messageId: customID));
    } else {
      if (trying < 5) {
        await connect();
        return query(_queryBuilder,
            trying: trying++, customID: customID, stream: stream);
      } else {
        return SocketData.fromFullData(
            {'success': false, "reason": "No Connection"});
      }
    }
  }

  /// Listen changes one document in a collection
  ///
  /// listenDocument(QueryBuilder)
  /// listenDocument(collection("my_col").[where].[filter].[sort].[limit].[offset])
  /// see [collection]  function document
  /// for learn that , How to create [QueryBuilder]
  /// return [SocketDataListener]
  ///
  /// for listening starting can call [listen] method of [SocketDataListener]
  SocketDataListener listenDocument(QueryBuilder _query, {int trying = 0}) {
    return SocketDataListener(_query);
  }

  ///
  StreamSubscription<SocketData> listenChat(
      void Function(SocketData data) onData) {
    return ChatDataListener().listen(onData);
  }

  /// Insert one document in a collection
  ///
  /// insertQuery(QueryBuilder , DocumentData)
  /// insertQuery(collection("my_col").[where].[filter].[sort].[limit].[offset] , [Map])
  /// see [collection]  function document
  /// for learn that , How to create [QueryBuilder]
  /// return [Future<SocketData>]
  ///
  /// can check success in [SocketData] instance member of [isSuccess]
  /// function will not return inserted document anywhere
  Future<SocketData> insertQuery(
      QueryBuilder _queryBuilder, Map<String, dynamic> document,
      {int trying = 0}) async {
    if (connected) {
      var _query =
          _queryBuilder.toQuery(QueryType.insert, token: options.token);
      _query.document = document;
      return sendAndWaitMessage(
          SocketData.create(
              data: <String, dynamic>{'query': _query.toJson()}, type: "query"),
          encrypted: true);
    } else {
      if (trying < 5) {
        await connect();
        return insertQuery(_queryBuilder, document, trying: trying++);
      } else {
        return SocketData.fromFullData(
            {'success': false, "reason": "No Connection"});
      }
    }
  }

  /// Query multiple documents in a collection
  ///
  ///
  /// listQuery(QueryBuilder)
  /// listQuery(collection("my_col").[where].[filter].[sort].[limit].[offset])
  /// see [collection]  function document
  /// for learn that , How to create [QueryBuilder]
  /// return [Future<List<Map<String, dynamic>>?>]
  ///
  /// if query success function return each document as [Map]
  /// Document [Map] is not be null, but List is may be null
  /// If [List] is null , query doesn't success,
  /// But if [List] is empty , query success and result 0 match
  Future<List<Map<String, dynamic>>?> listQuery(QueryBuilder _queryBuilder,
      {int trying = 0}) async {
    if (connected) {
      var _query =
          _queryBuilder.toQuery(QueryType.listQuery, token: options.token);

      var dat = await sendAndWaitMessage(SocketData.create(
          data: <String, dynamic>{'query': _query.toJson()}, type: "query"));
      if (dat.isSuccess) {
        var _process = <Map<String, dynamic>>[];

        for (var _p in dat.data!['list']) {
          _process.add(_p);
        }

        return _process;
      } else {
        return [];
      }
    } else {
      if (trying < 5) {
        await connect();
        return listQuery(_queryBuilder, trying: trying++);
      } else {
        return [];
      }
    }
  }

  // String _byteCountToString(int byte) {
  //   if (byte < 1024) {
  //     return '$byte B';
  //   } else if (byte < 1024 * 1024) {
  //     var kb = (byte / 1024 * 100).floor() / 100;
  //     return '$kb Kb';
  //   } else if (byte < 1024 * 1024 * 1024) {
  //     var mb = (byte / (1024 * 1024) * 100).floor() / 100;
  //     return '$mb Mb';
  //   } else {
  //     var gb = (byte / (1024 * 1024 * 1024) * 100).floor() / 100;
  //     return '$gb gb';
  //   }
  // }

  /// Query documents is exists in a collection
  ///
  /// exists(QueryBuilder)
  /// exists(collection("my_col").[where].[filter].[sort].[limit].[offset])
  /// see [collection]  function document
  /// for learn that , How to create [QueryBuilder]
  /// return [Future<bool?>]
  ///
  /// if query success function return document exists
  /// If return value is null , query doesn't success,
  Future<bool?> exists(QueryBuilder _queryBuilder, {int trying = 0}) async {
    if (connected) {
      var _query =
          _queryBuilder.toQuery(QueryType.exists, token: options.token);

      var dat = await sendAndWaitMessage(SocketData.create(
          data: <String, dynamic>{'query': _query.toJson()}, type: "query"));

      return dat.data!['exists'];
    } else {
      if (trying < 5) {
        await connect();
        return exists(_queryBuilder, trying: trying++);
      } else {
        return null;
      }
    }
  }

  /// Delete one document in a collection
  ///
  /// delete(QueryBuilder)
  /// delete(collection("my_col").[where].[filter].[sort].[limit].[offset])
  /// see [collection]  function document
  /// for learn that , How to create [QueryBuilder]
  /// return [Future<bool?>]
  ///
  /// if query success function return document deleted
  /// If return value is null , query doesn't success,
  Future<bool?> delete(QueryBuilder _queryBuilder, {int trying = 0}) async {
    if (connected) {
      var _query =
          _queryBuilder.toQuery(QueryType.delete, token: options.token);

      var dat = await sendAndWaitMessage(SocketData.create(
          data: <String, dynamic>{'query': _query.toJson()}, type: "query"));

      return dat.isSuccess;
    } else {
      if (trying < 5) {
        await connect();
        return exists(_queryBuilder, trying: trying++);
      } else {
        return null;
      }
    }
  }

  ///bağlantı
  Future<bool> connect([int i = 0]);

/*  async {
  try {
  // ignore: avoid_print
  print('CONNECTION ${socket?.readyState ?? 'null'}');

  if (socket == null || socket?.readyState == 3) {
  socket =
  await WebSocket.connect("ws://$globalHostName:$webSocketPort/ws");
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
  _streamController.sink.add(event);
  }, onError: (e) {
  // ignore: avoid_print
  print("ON ERROR::::$e");
  connected = false;
  }, onDone: () {
  connected = false;
  });
  } on Exception catch (e) {
  socket = null;
  await connect(i++);
  }

  socketConnection.listen((event) {
  _downloadBytes += (event.length * 2) as int;
  // ignore: avoid_print

  var dat = json.decode(event);

  if (dat['type'] != null && dat['type'] == 'connection_confirmation') {
  dat['device_id'] = deviceID;
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
  }*/

  ///Bağlantı izni isteme
  ///4 aşamadan oluşuyor
  @protected
  Future<bool> requestConnection() async {
    try {
      // ignore: avoid_print
      // print('Connection Requested');
      // HttpClient client = new HttpClient();
      // client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

      //
      // var req = await client.getUrl(Uri.parse(
      //     'http${options.secure ? "s" : ""}://${options.globalHostName}:${options.mediaServerPort}/socket_request'));
      //
      // var res =await req.close();
      //

      var response = await get(Uri.parse(
          'http${options.secure ? "s" : ""}://${options.globalHostName}:${options.mediaServerPort}/socket_request'));




      var decodedResponse = json.decode(response.body);

      if (decodedResponse['success'] != null &&
          decodedResponse['success'].runtimeType == bool &&
          decodedResponse['success']) {
        options.deviceID = decodedResponse['req_id'];

        // ignore: avoid_print
        // print('DEVICE ID RECEIVED : ${deviceID?.length}');

        ///
        ///                       type
        ///                       -----
        ///                        id
        ///
        ///
        ///   Server Side                            Client Side
        ///
        ///
        ///   deviceID       request_connection
        ///       |      <-----------------------     deviceID
        ///       |               requestID
        ///       |
        ///       |
        ///       |
        ///       |           nonce_sending
        ///  serverNonce  ------------------------>  serverNonce
        ///                     requestID                 |
        ///                                               |
        ///                                               |
        ///                                               |
        ///                                               |
        ///   auth_data      c_nonce_sending            auth_data
        ///  clientNonce  <--------------------------  clientNonce
        ///       |              secondID
        ///       |
        ///       |
        ///       |
        ///       |
        ///       |           token_sending                 ✅
        ///  auth_token   --------------------------->  auth token
        ///                     secondID                    ✅
        ///
        ///

        ///First Connection Request
        var requestID = Statics.getRandomId(30);

        ///Sending "request_connection" and waiting "nonce_sending"
        var stage2Data = await sendAndWaitMessage(
            SocketData.fromFullData({
              'message_id': requestID,
              'device_id': options.deviceID,
              'message_type': 'request_connection',
              "data": {}
            }),
            encrypted: false);

        if (!stage2Data.isSuccess) {
          throw Exception('Unsuccessful connection ${stage2Data.isSuccess}');
        }

        // ignore: avoid_print
        // print("STAGE 2 'ye erişimlidi : ${stage2Data.fullData}");

        ///server side nonce
        options.nonce = TypeCasts.nonceCast(stage2Data.fullData!['nonce']);

        ///generate client nonce
        options.cNonce = Nonce.random();
        var authService = AuthService();



        ///ADD remember operations
        ///daha sonra eklencek
        ///auth servisinden gerekli bilgiler
        ///alınıp guess değil auth user olarak bilgiler gönderilecek
        var authData = await authService.initialAuthData;

        var secondID = Statics.getRandomId(30);

        var da = SocketData.fromFullData({
          'message_id': secondID,
          'message_type': 'c_nonce_sending',
          'data': authData,
          'device_id': options.deviceID,
          'c_nonce': options.cNonce!.list
        });

        await da.encrypt();

        ///Sending "c_nonce_sending" and waiting 'token_sending'
        var stage4Data = await sendAndWaitMessage(da, encrypted: false);

        ///Token received
        await stage4Data.decrypt();


        options.token = stage4Data.data!['token'];

        if (stage4Data.data!['auth_type'] == 'auth' && options.token != null) {
          await authService.loginWithTokenInit(
              options.token, stage4Data.data!['user_data']);
        }

        // ignore: avoid_print
        // print("CONNECTING VALIDATED");
        return true;
      } else {
        // ignore: avoid_print
        // print("CONNECTING NOT VALIDATED");
        return false;
      }
    } on MissingRequiredKeysException {
      return false;
    } on Exception catch (e) {
      // ignore: avoid_print
      print('ERROR ON REQUEST CONNECTION : ${e.runtimeType} : $e');
      return false;
    }
  }

  ///Close connection
  void close() {
    options.close();

    var _sendingData = json.encode({
      'type': 'close',
      'id': Statics.getRandomId(15),
      'device_id': options.deviceID,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      "data": {}
    });
    var _sendingBytes = _sendingData.length * 2;
    options.uploadBytes += _sendingBytes;

    sendMessage(_sendingData);

    // ignore: avoid_print
    // print(
    //     'SENDING::::${_byteCountToString(_sendingBytes)} / ${_byteCountToString(_uploadBytes)}');

    connected = false;
    closeSocket();
  }

  ///
  closeSocket();
}
