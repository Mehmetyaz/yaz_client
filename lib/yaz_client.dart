library yaz_client;

import 'package:flutter/material.dart';

import 'package:yaz_client/src/services/encryption.dart';
import "src/socket_service.dart" show socketService;

export 'package:yaz_client/src/models/stream_socket_data.dart'
    show SocketDataListener;
export "src/socket_service.dart" show socketService;
export 'src/extensions/date_time.dart';
export 'src/extensions/duration.dart';
export 'package:yaz_client/src/models/query_model/query_model.dart' show Query;
export 'package:yaz_client/src/models/socket_data/socket_data.dart'
    show SocketData;
export 'package:yaz_client/src/models/user/current_user.dart' show CurrentUser;
export 'package:yaz_client/src/models/user/user_model.dart' show YazApiUser;
export 'package:yaz_client/src/services/auth_service.dart' show authService;
export 'package:yaz_client/src/statics/image_size.dart' show ImageSize;
export 'package:yaz_client/src/statics/query_type.dart' show QueryType;
export 'package:yaz_client/src/statics/sorting.dart' show Sorting;
export 'package:yaz_client/src/services/chat/chat.dart'
    show
        YazChatMessage,
        YazChatConversation,
        YazChatListWidget,
        YazMessageListWidget,
        chatService;
export 'package:yaz_client/src/statics/statics.dart'
    show UserModelStatics, Statics, TypeCasts;
export 'package:yaz_client/src/extensions/duration.dart';
export 'package:yaz_client/src/extensions/date_time.dart';

class YazClient {
  static void init(
      {required String secret1,
      required String secret2,
      required String host,
      required String port}) {
    EncryptionService().init(secret1, secret2);
    socketService.init(host, port);
  }
}



String greet(){
  return "Hello word!";
}



