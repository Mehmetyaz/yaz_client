// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YazChatMessage _$YazChatMessageFromJson(Map<String, dynamic> json) {
  $checkKeys(json,
      requiredKeys: const ['sender_id', 'receiver_id', 'receiver_seen']);
  return YazChatMessage(
    json['sender_id'] as String,
    json['receiver_id'] as String,
    json['message_id'] as String,
    json['message_content'] as String,
    json['message_type'] as String,
    json['conversation_id'] as String,
  )
    ..sendDate = UserModelStatics.dateFromJson(json['message_time'] as int)
    ..receiveDate = UserModelStatics.dateFromJson(json['receive_time'] as int)
    ..seenDate = UserModelStatics.dateFromJson(json['seen_time'] as int)
    ..receiverSeen = json['receiver_seen'] as bool;
}

Map<String, dynamic> _$YazChatMessageToJson(YazChatMessage instance) =>
    <String, dynamic>{
      'message_time': UserModelStatics.dateToInt(instance.sendDate),
      'receive_time': UserModelStatics.dateToInt(instance.receiveDate),
      'seen_time': UserModelStatics.dateToInt(instance.seenDate),
      'sender_id': instance.senderId,
      'receiver_id': instance.receiverId,
      'receiver_seen': instance.receiverSeen,
      'message_id': instance.messageId,
      'message_content': instance.content,
      'message_type': instance.type,
      'conversation_id': instance.conversationId,
    };

YazChatConversation _$YazChatConversationFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const [
    'conversation_id',
    'starter_id',
    'receiver_id',
    'total_message_count'
  ]);
  return YazChatConversation(
    json['conversation_id'] as String,
    json['starter_id'] as String,
    json['receiver_id'] as String,
  )
    ..lastActivity = UserModelStatics.dateFromJson(json['last_activity'] as int)
    ..totalMessageCount = json['total_message_count'] as int;
}

Map<String, dynamic> _$YazChatConversationToJson(
        YazChatConversation instance) =>
    <String, dynamic>{
      'conversation_id': instance.chatId,
      'starter_id': instance.starter,
      'receiver_id': instance.receiver,
      'last_activity': UserModelStatics.dateToInt(instance.lastActivity),
      'total_message_count': instance.totalMessageCount,
    };
