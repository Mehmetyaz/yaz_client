// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chat _$ChatFromJson(Map<String, dynamic> json) {
  return Chat()
    ..chatId = json['chat_id'] as String
    ..starter = json['starter_id'] as String
    ..receiver = json['receiver_id'] as String
    ..lastActivitySeenSender = json['last_activity_seen_sender'] as int
    ..lastActivitySeenReceiver = json['last_activity_seen_receiver'] as int
    ..totalMessageCount = json['total_message_count'] as int
    ..lastActivity = UserModelStatics.dateFromJson(json['last_activity'] as int)
    ..isStarterWriting = json['is_starter_writing'] as bool
    ..isReceiverWriting = json['is_receiver_writing'] as bool;
}

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
      'chat_id': instance.chatId,
      'starter_id': instance.starter,
      'receiver_id': instance.receiver,
      'last_activity_seen_sender': instance.lastActivitySeenSender,
      'last_activity_seen_receiver': instance.lastActivitySeenReceiver,
      'total_message_count': instance.totalMessageCount,
      'last_activity': UserModelStatics.dateToInt(instance.lastActivity),
      'is_starter_writing': instance.isStarterWriting,
      'is_receiver_writing': instance.isReceiverWriting,
    };
