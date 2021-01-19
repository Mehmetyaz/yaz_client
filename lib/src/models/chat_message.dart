import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../yaz_client.dart';

part 'chat_message.g.dart';

///
@JsonSerializable()
class ChatMessage extends Comparable with ChangeNotifier {
  ChatMessage();

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage.create(this.message, this.chatId, {this.messageType = "text"})
      : time = DateTime.now(),
        isResponse = false,
        sender = authService.userID,
        messageId = Statics.getRandomId(30){
    sent = false;
  }

  bool operator ==(other) {
    if (other is ChatMessage) {
      return this.messageId == other.messageId;
    }

    return false;
  }

  @JsonKey(defaultValue: true)
  bool seenByOwn = false;

  @JsonKey(ignore: true)
  bool seenByOther = false;

  ///
  @JsonKey(ignore: true)
  bool sent = true;

  seenOther(int last) {
    if (!seenByOther) {
      seenByOther = time.millisecondsSinceEpoch < last;
      notifyListeners();
    }
  }

  seen(int last){
    if (!seenByOwn) {
      seenByOwn = time.millisecondsSinceEpoch < last;
      notifyListeners();
    }
  }


  ///
  @JsonKey(name: "message_id", nullable: false)
  String messageId;

  @JsonKey(name: "sender", nullable: false)
  String sender;

  ///
  @JsonKey(name: "message_type", nullable: false)
  String messageType;

  ///
  @JsonKey(name: "message_content")
  String message;

  ///
  @JsonKey(
      name: "message_time",
      nullable: false,
      fromJson: UserModelStatics.dateFromJson,
      toJson: UserModelStatics.dateToInt)
  DateTime time;

  ///
  @JsonKey(name: "is_response")
  bool isResponse = false;

  ///
  @JsonKey(name: "response_message_id", nullable: true)
  String responseMessageID;

  ///
  @JsonKey(name: "chat_id", nullable: false)
  String chatId;

  @override
  int compareTo(other) {
    if (other is ChatMessage) {
      return this.time.compareTo(other.time);
    }

    return -1;
  }

  @override
  int get hashCode => messageId.hashCode;
}
