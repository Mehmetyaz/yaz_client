import 'package:yaz_client/src/services/web_socket_abstract.dart'
    show WebSocketServiceBase;

import "web_socket_service_mobile.dart"
    if (dart.library.io) "web_socket_service_mobile.dart"
    if (dart.library.html) "web_socket_service_web.dart"
    if (dart.library.js) "web_socket_service_web.dart"
    show socketServiceInternal;

WebSocketServiceBase get socketService {
  return socketServiceInternal;
}
