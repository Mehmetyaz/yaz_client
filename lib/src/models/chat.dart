import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaz_client/yaz_client.dart';

import 'chat_message.dart';
import '../services/chat_service.dart';

part 'chat.g.dart';

@JsonSerializable()
class Chat extends Comparable with ChangeNotifier {
  ///
  @protected
  Chat();

  factory Chat.fromJson(Map<String, dynamic> json) {
    print("CHAT OLUŞTU");

    return _$ChatFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ChatToJson(this);

  @JsonKey(name: "chat_id", nullable: false)
  String chatId;

  @JsonKey(name: "starter_id", nullable: false)
  String starter;

  @JsonKey(name: "receiver_id", nullable: false)
  String receiver;

  @JsonKey(ignore: true)
  final MessageList messageList = MessageList();

  // List<ChatMessage> get messages {
  //   return messageList[chatId];
  // }
  @JsonKey(ignore: true)
  List<ChatMessage> get messages {
    return messageList[chatId];
  }

  @JsonKey(ignore: true)
  ChatMessage get lastMessage {
    if (messageList[chatId] != null && messageList[chatId].isEmpty) {
      return null;
    }

    return messageList[chatId].first;
  }

  bool get isEmpty {
    return messageList[chatId].isEmpty;
  }

  @JsonKey(ignore: true)
  bool hasMore = true;

  @JsonKey(ignore: true)
  bool loaded = false;

  loadMore(Function onLoad) async {
    print("LOAD MORE");
    if (!loaded && hasMore) {
      if (totalMessageCount > messageCount) {
        print("LOAD MORE1");
        loaded = true;
        notifyListeners();
        var _nMessages = await socketService
            .listQuery(Query.create("messages", limit: 100, filters: {
          "lt": {
            "message_time": messageList[chatId].last.time.millisecondsSinceEpoch
          }
        }, equals: {
          "chat_id": chatId
        }));

        if (_nMessages.length == 0) {
          hasMore = false;
        }

        print("LOAD MORE2 : ${_nMessages.length}");
        messageList.addAll(
            chatId, _nMessages.map<ChatMessage>((e) => ChatMessage.fromJson(e))
            .toList(),
            last: true);
        loaded = false;
        notifyListeners();
      }
    }
  }

  // @JsonKey(
  //     ignore: false, name: "init_messages", defaultValue: const <ChatMessage>[])
  // List<ChatMessage> messages;

  @JsonKey(name: "last_activity_seen_sender")
  int lastActivitySeenSender = 0;

  @JsonKey(name: "last_activity_seen_receiver")
  int lastActivitySeenReceiver = 0;

  @JsonKey(ignore: false, nullable: false, name: "total_message_count")
  int totalMessageCount;

  // bool get allSeen {
  //   print("MESSAGES : ${messages.isEmpty}");
  //
  //   if (messages == null || messages.isEmpty) {
  //     return true;
  //   } else {
  //     print("ALL SEEN : ${messages[0].seenByOwn}");
  //     return messages[0].seenByOwn;
  //   }
  // }
  @JsonKey(ignore: true)
  bool allSeen = false;


  seeAll() {
    if (!allSeen) {
      allSeen = true;
      chatService.seen(chatId);
      if (isStarter) {
        lastActivitySeenSender = DateTime
            .now()
            .millisecondsSinceEpoch;
      } else {
        lastActivitySeenReceiver = DateTime
            .now()
            .millisecondsSinceEpoch;
      }

      for (var m in messageList[chatId]) {
        if (m.seenByOwn) {
          break;
        }
        m.seen(lastActivityOtherSeen);
      }
      notifyListeners();
    }
  }

  updateSeenReceived(SocketData data) {
    if (isStarter) {
      lastActivitySeenReceiver = data["last_activity_seen_receiver"];
    } else {
      lastActivitySeenSender = data["last_activity_seen_sender"];
    }

    for (var m in messageList[chatId]) {
      if (m.seenByOther) {
        break;
      }
      m.seenOther(lastActivityOtherSeen);
    }

    notifyListeners();
  }

  ///
  addNewMessage(ChatMessage message) {
    messageList.add(chatId, message);
    allSeen = false;

    // if (key != null && key.currentState != null && key.currentState.mounted) {
    //   print(key.currentState.widget.initialItemCount);
    //   print(messageCount);
    //   key.currentState.insertItem(messageCount - 1);
    // }
    lastActivity = message.time;
    if (isStarter) {
      lastActivitySeenSender = message.time.millisecondsSinceEpoch;
    } else {
      lastActivitySeenReceiver = message.time.millisecondsSinceEpoch;
    }

    notifyListeners();
  }

  int get lastActivitySeen {
    return isStarter ? lastActivitySeenSender : lastActivitySeenReceiver;
  }

  int get lastActivityOtherSeen {
    return !isStarter ? lastActivitySeenSender : lastActivitySeenReceiver;
  }

  bool get isStarter {
    return authService.userID == starter;
  }

  ///
  int get notOtherSeenMessageCount {
    int res = 0;
    for (var message in messageList[chatId]) {
      if (message.seenByOther) {
        res++;
      } else {
        break;
      }
    }
    return res;
  }

  ///
  int get notSeenMessageCount {
    int res = 0;
    for (var message in messageList[chatId]) {
      if (!message.seenByOwn) {
        res++;
      } else {
        break;
      }
    }
    return res;
  }

  int get messageCount {
    return messageList[chatId].length;
  }

  @JsonKey(
      ignore: false,
      nullable: false,
      name: "last_activity",
      fromJson: UserModelStatics.dateFromJson,
      toJson: UserModelStatics.dateToInt)
  DateTime lastActivity;

  @JsonKey(name: "is_starter_writing")
  bool isStarterWriting = false;

  @JsonKey(name: "is_receiver_writing")
  bool isReceiverWriting = false;

  Future<void> cache() async {
    var list = await socketService.listQuery(Query.create("messages",
        sorts: <String, Sorting>{
          "message_time": Sorting.descending,
        },
        equals: {"chat_id": chatId},
        limit: 5));
    messageList.addAll(
        chatId, list.map<ChatMessage>((e) => ChatMessage.fromJson(e)).toList());

    return null;
  }


  String get otherUserId {
    return !isStarter ? starter : receiver;
  }

  String get currentUserID {
    return isStarter ? starter : receiver;
  }

  sendMessage(String body, String type) {
    var newM = ChatMessage.create(body, this.chatId);
    chatService.sendMessage(newM);
  }

  @override
  int compareTo(other) {
    assert(
    other is Chat || other is DateTime, "Chat compare to chat or DateTime");

    if (other is DateTime) {
      return this.lastActivity.compareTo(other);
    } else if (other is Chat) {
      return this.lastActivity.compareTo(other.lastActivity);
    } else {
      return -1;
    }
  }
}
