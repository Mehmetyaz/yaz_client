class MissingWebSocketArguments implements Exception {
  MissingWebSocketArguments({this.hostIsNull, this.portIsNull});

  final bool? portIsNull;
  final bool? hostIsNull;

  @override
  String toString() =>
      "Missing Arguments:"
          " ${hostIsNull! ? "WebSocket Host" : " , "}"
          " ${portIsNull! ? "WebSocket Port" : ""}\nPlease Init once";
}
