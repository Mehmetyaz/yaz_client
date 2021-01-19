// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return ChatMessage()
    ..seenByOwn = json['seenByOwn'] as bool ?? true
    ..messageId = json['message_id'] as String
    ..sender = json['sender'] as String
    ..messageType = json['message_type'] as String
    ..message = json['message_content'] as String
    ..time = UserModelStatics.dateFromJson(json['message_time'] as int)
    ..isResponse = json['is_response'] as bool
    ..responseMessageID = json['response_message_id'] as String
    ..chatId = json['chat_id'] as String;
}

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'seenByOwn': instance.seenByOwn,
      'message_id': instance.messageId,
      'sender': instance.sender,
      'message_type': instance.messageType,
      'message_content': instance.message,
      'message_time': UserModelStatics.dateToInt(instance.time),
      'is_response': instance.isResponse,
      'response_message_id': instance.responseMessageID,
      'chat_id': instance.chatId,
    };
