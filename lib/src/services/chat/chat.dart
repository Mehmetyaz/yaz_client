import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaz_client/src/statics/chat_strings.dart';
import 'package:yaz_client/yaz_client.dart';
import '../message_list.dart';
import 'keep_alive_widget.dart';

part 'chat.g.dart';

part 'yaz_chat_list_widget.dart';

part 'yaz_conversation_widget.dart';

YazChatService chatService = YazChatService();

class YazChatService extends ChangeNotifier {
  factory YazChatService() => _instance;

  YazChatService._();

  static final YazChatService _instance = YazChatService._();

  YazChatConversation? operator [](String chatId) {
    return _conversations[chatId];
  }

  final HashMap<String?, YazChatConversation> _conversations =
      HashMap.from(<String, YazChatConversation>{});
  final List<String> _conversationsIds = <String>[];

  Future<YazChatConversation> startChat(String userWith) async {
    var _id = Statics.getRandomId(30);

    var ex = _conversations.values.where((element) => element.isStarter
        ? element.receiver == userWith
        : element.starter == userWith);

    if (ex.isNotEmpty) return ex.first;

    collection(CHAT_COLLECTIONS)
      ..where("receiver_id", isEqualTo: authService.userID);
    var existStarted = socketService.exists(collection(CHAT_COLLECTIONS)
      ..where("starter_id", isEqualTo: authService.userID));

    var existsReceived = socketService.exists(collection(CHAT_COLLECTIONS)
      ..where("receiver_id", isEqualTo: authService.userID));

    var l = [await existStarted, await existsReceived];

    if (l.contains(true)) {
      var builder = collection(CHAT_COLLECTIONS);
      if ((await existsReceived)!) {
        builder.where("receiver_id", isEqualTo: authService.userID);
      } else {
        builder.where("starter_id", isEqualTo: authService.userID);
      }
      var newChatMe = await socketService.query(builder);

      var chat = YazChatConversation.fromJson((newChatMe).data!);

      _conversations[chat.chatId] = chat;

      if (!_conversationsIds.contains(chat.chatId)) {
        _conversationsIds.insert(0, chat.chatId);
      }

      return chat;
    }

    var chatJson = await socketService.customOperation(
        START_CHAT_OPERATION,
        {
          "receiver": userWith,
          CONVERSATION_ID: _id,
        },
        useToken: true);

    var chat = YazChatConversation.fromJson(chatJson.data!["document"]);
    _conversations[chat.chatId] = chat;
    if (!_conversationsIds.contains(chat.chatId)) {
      _conversationsIds.insert(0, chat.chatId);
    }

    notifyListeners();
    return chat;
  }

  _sort() {
    var c = <String>[];

    for (var r in _conversationsIds) {
      if (!c.contains(r)) {
        c.add(r);
      }
    }

    _conversationsIds.clear();
    _conversationsIds.addAll(c);

    /// Sort desc
    _conversationsIds
        .sort((a, b) => _conversations[b]!.compareTo(_conversations[a]));
  }

  _listen() {
    socketService.listenChat((data) async {
      if (data["type"] != null) {
        switch (data["type"]) {
          case NEW_MESSAGE_FROM_OTHER:
            var _conId = data["conversation_data"][CONVERSATION_ID];
            if (!_conversations.containsKey(_conId)) {
              await _addReceivedNewConversation(
                  YazChatConversation.fromJson(data["conversation_data"]));
            }
            _conversations[_conId]!
              .._handleNewMessage(YazChatMessage.fromJson(data["message"]))
              .._update(
                  YazChatConversation.fromJson(data["conversation_data"]));
            _sort();
            notifyListeners();
            break;
          case MESSAGE_SEEN_BY_OTHER:
            var chat = data[CONVERSATION_ID] as String?;
            _conversations[chat]!
                ._handleSee(DateTime.fromMillisecondsSinceEpoch(data["time"]));
            break;
          case NEW_MESSAGE_FROM_OWN:
            var chat = data[CONVERSATION_ID] as String?;
            if (!_conversations
                .containsKey(data["conversation_data"][CONVERSATION_ID])) {
              await _addReceivedNewConversation(
                  YazChatConversation.fromJson(data["conversation_data"]));
            }
            _conversations[chat]!
              .._handleOwnMessage(
                  YazChatMessage.fromJson(data.data!["message"]))
              .._update(
                  YazChatConversation.fromJson(data["conversation_data"]));
            _sort();
            notifyListeners();
            break;
          case MESSAGE_SEEN_BY_OWN:
            var chat = data[CONVERSATION_ID] as String?;
            _conversations[chat]!._handleSeenReceives();
            break;
        }
      }
    });
  }

  Future<void> _addReceivedNewConversation(
      YazChatConversation conversation) async {
    try {
      _conversations[conversation.chatId] = conversation;
      if (!_conversationsIds.contains(conversation.chatId)) {
        _conversationsIds.insert(0, conversation.chatId);
      }

      _sort();
      notifyListeners();

      return;
    } catch (e) {}
  }

  Future<List<YazChatConversation>> _getAllConversations() async {
    var chatListData =
        await socketService.listQuery(collection(CHAT_COLLECTIONS)
          ..where("starter_id", isEqualTo: authService.userID)
          ..sort(LAST_ACTIVITY, Sorting.descending));

    var chatListData2 =
        await socketService.listQuery(collection(CHAT_COLLECTIONS)
          ..where("receiver_id", isEqualTo: authService.userID)
          ..sort(LAST_ACTIVITY, Sorting.descending));

    chatListData!.addAll(chatListData2!);

    return (chatListData)
        .map<YazChatConversation>((e) => YazChatConversation.fromJson(e))
        .toList();
  }

  // _createIfNotExists() {
  //   socketService
  //       .exists(Query.create("user_chat_documents",
  //       equals: {"user_id": authService.userID}))
  //       .then((value) {
  //     if (value == null || (value != null && !value)) {
  //       socketService.insertQuery(Query.create("user_chat_documents",
  //           document: {"user_id": authService.userID}));
  //     }
  //   });
  // }


  bool initialized = false;

  Future<void> init() async {
    if (initialized) return;
    initialized = true;
    if (!authService.isLoggedIn) {
      return null;
    }
    // _createIfNotExists();

    var _initialList = await _getAllConversations();

    /// Sort Descending
    _initialList.sort((a, b) => b.compareTo(a));


    /// add descending
    _conversationsIds.addAll(_initialList.map((e) => e.chatId));


    _conversations.addEntries(_initialList
        .map<MapEntry<String?, YazChatConversation>>(
            (e) => MapEntry(e.chatId, e))
        .toList());

    var ftrs = <Future<void>>[];

    ftrs.addAll(_conversations.values.map((e) => e._cache()));

    await Future.wait(ftrs);

    _listen();

    /// Adding initial completed
    return;
  }

  final MessageList messageList = MessageList();

  _notify() {
    notifyListeners();
  }

  int get notSeenMessageCount {
    var res = 0;
    for (var c in _conversations.values) {
      res += c.notSeenMessageCount;
    }
    return res;
  }
}

@JsonSerializable()
class YazChatMessage extends Comparable with ChangeNotifier {
  YazChatMessage(
      {required this.senderId,
      required this.receiverId,
      required this.messageId,
      required this.content,
      required this.type,
      required this.conversationId,
      required this.receiverSeen,
      required this.sent,
      this.seenDate,
      this.receiveDate,
      this.sendDate});

  factory YazChatMessage.fromJson(Map<String, dynamic> map) => YazChatMessage(
      senderId: map["sender_id"],
      receiverId: map["receiver_id"],
      messageId: map["message_id"],
      content: map["message_content"],
      type: map["message_type"],
      conversationId: map[CONVERSATION_ID],
      receiverSeen: map["receiver_seen"],
      sent: true,
      receiveDate: map[RECEIVE_TIME] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[RECEIVE_TIME])
          : null,
      seenDate: map[SEEN_TIME] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[SEEN_TIME])
          : null,
      sendDate: map[MESSAGE_TIME] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[MESSAGE_TIME])
          : null);

  Map<String, dynamic> toJson() => {
        CONVERSATION_ID: conversationId,
        MESSAGE_TIME: sendDate?.millisecondsSinceEpoch,
        RECEIVE_TIME: receiveDate?.millisecondsSinceEpoch,
        SEEN_TIME: seenDate?.millisecondsSinceEpoch,
        "sender_id": senderId,
        "receiver_id": receiverId,
        "receiver_seen": receiverSeen,
        "message_id": messageId,
        "message_content": content,
        "message_type": type
      };

  YazChatMessage.create(this.content,
      {this.type = "text",
      required YazChatConversation chatConversation,
      String? customID})
      : conversationId = chatConversation.chatId,
        receiverSeen = false,
        receiverId = chatConversation.otherId,
        senderId = chatConversation.ownId,
        sendDate = DateTime.now(),
        messageId = customID ?? Statics.getRandomId(20);

  @JsonKey(ignore: true)
  bool sent = false;

  @JsonKey(
    name: MESSAGE_TIME,
    fromJson: UserModelStatics.dateFromJson,
    toJson: UserModelStatics.dateToInt,
  )
  DateTime? sendDate;

  @JsonKey(
    name: RECEIVE_TIME,
    fromJson: UserModelStatics.dateFromJson,
    toJson: UserModelStatics.dateToInt,
  )
  DateTime? receiveDate;

  @JsonKey(
    name: SEEN_TIME,
    fromJson: UserModelStatics.dateFromJson,
    toJson: UserModelStatics.dateToInt,
  )
  DateTime? seenDate;

  @JsonKey(name: "sender_id", required: true)
  final String senderId;

  @JsonKey(name: "receiver_id", required: true)
  final String receiverId;

  @JsonKey(name: "receiver_seen", required: true)
  bool receiverSeen;

  @JsonKey(name: "message_id")
  final String messageId;

  @JsonKey(name: "message_content")
  final String content;

  @JsonKey(name: "message_type")
  final String type;

  @JsonKey(name: CONVERSATION_ID)
  final String conversationId;

  bool get currentUserIsSender {
    return authService.currentUser!.userID == senderId;
  }

  bool get seenReceived {
    return !currentUserIsSender && receiverSeen;
  }

  bool get seenSent {
    return currentUserIsSender && receiverSeen;
  }

  /// This function only change local info
  void _see() {
    receiverSeen = true;
    notifyListeners();
  }

  void _notifySend() {
    sent = true;
    notifyListeners();
    return;
  }

  @override
  int compareTo(other) {
    if (other is YazChatMessage) {
      return this.sendDate!.compareTo(other.sendDate!);
    }
    return -1;
  }
}

// Map<String, dynamic> _$YazChatMessageToJson(YazChatMessage yazChatMessage) {
//   return {
//
//   };
// }

@JsonSerializable()
class YazChatConversation extends Comparable with ChangeNotifier {
  YazChatConversation(
      {required this.chatId,
      required this.starter,
      required this.receiver,
      required this.lastActivity,
      required this.totalMessageCount});

  factory YazChatConversation.fromJson(Map<String, dynamic> json) =>
      YazChatConversation(
          chatId: json[CONVERSATION_ID],
          starter: json["starter_id"],
          receiver: json["receiver_id"],
          lastActivity: json[LAST_ACTIVITY] == null
              ? DateTime(1970)
              : DateTime.fromMillisecondsSinceEpoch(json[LAST_ACTIVITY]),
          totalMessageCount: json["total_message_count"]);

  Map<String, dynamic> toJson() => {
        CONVERSATION_ID: chatId,
        "starter_id": starter,
        "receiver_id": receiver,
        LAST_ACTIVITY: lastActivity.millisecondsSinceEpoch,
        "total_message_count": totalMessageCount
      };

  @JsonKey(name: CONVERSATION_ID, required: true)
  final String chatId;

  @JsonKey(name: "starter_id", required: true)
  final String starter;

  @JsonKey(name: "receiver_id", required: true)
  final String receiver;

  @JsonKey(ignore: true)
  final MessageList messageList = MessageList();

  @JsonKey(
    name: LAST_ACTIVITY,
    fromJson: UserModelStatics.dateFromJson,
    toJson: UserModelStatics.dateToInt,
  )
  DateTime lastActivity;

  @JsonKey(ignore: true)
  List<YazChatMessage>? get messages {
    return messageList[chatId];
  }

  @JsonKey(ignore: true)
  YazChatMessage? get lastMessage {
    if (messageList[chatId] == null) return null;

    if (messageList[chatId] != null && messageList[chatId]!.isEmpty) {
      return null;
    }

    return (messageList[chatId]!).first;
  }

  @JsonKey(ignore: true)
  bool get isEmpty {
    return messageList[chatId]!.isEmpty;
  }

  @override
  int compareTo(other) {
    if (other is YazChatConversation) {
      return this.lastActivity.compareTo(other.lastActivity);
    }
    return -1;
  }

  Future<void> _cache() async {
    var list = await socketService.listQuery(collection(MESSAGE_COLLECTION)
        .where(CONVERSATION_ID, isEqualTo: chatId)
        .sort(MESSAGE_TIME, Sorting.descending)
        .limit(5));
    messageList.addAll(chatId,
        list!.map<YazChatMessage>((e) => YazChatMessage.fromJson(e)).toList());

    _allSeen = messages!.any((element) => !element.receiverSeen);
    return null;
  }

  @JsonKey(ignore: true)
  bool hasMore = true;

  @JsonKey(ignore: true)
  bool loaded = false;

  @JsonKey(ignore: false, required: true, name: "total_message_count")
  int totalMessageCount;

  @JsonKey(ignore: true)
  int get messageCount {
    return (messageList[chatId] ?? []).length;
  }

  loadMore(Function onLoad) async {
    _allSeen = false;
    if (!loaded && hasMore) {
      if (totalMessageCount > messageCount) {
        loaded = true;
        notifyListeners();

        var _nMessages = await socketService.listQuery(
            collection(MESSAGE_COLLECTION)
                .where(CONVERSATION_ID, isEqualTo: chatId)
                .sort(MESSAGE_TIME, Sorting.descending)
                .filter(MESSAGE_TIME,
                    isLessThan: messageList[chatId]!
                        .last
                        .sendDate!
                        .millisecondsSinceEpoch)
                .limit(100));

        if (_nMessages!.length == 0) {
          hasMore = false;
        }

        messageList.addAll(
            chatId,
            _nMessages
                .map<YazChatMessage>((e) => YazChatMessage.fromJson(e))
                .toList(),
            last: true);
        loaded = false;
        notifyListeners();
      }
    }
  }

  @JsonKey(ignore: true)
  bool get isStarter {
    return authService.userID == starter;
  }

  String get otherId {
    return isStarter ? receiver : starter;
  }

  String get ownId {
    return isStarter ? starter : receiver;
  }

  @JsonKey(ignore: true)
  int get notSeenMessageCount {
    int res = 0;
    for (var message in (messageList[chatId] ?? [])
        .where((element) => !element.currentUserIsSender)) {
      if (!message.receiverSeen) {
        res++;
      } else {
        break;
      }
    }
    return res;
  }

  void build() async {
    seeReceives();
  }

  bool _allSeen = true;

  /// See all received messages
  void seeReceives({bool fromOther = false}) {
    if (_allSeen) return;
    bool allReceives = false, notify = false, change = false;
    for (var message in messages!) {
      allReceives = message.seenReceived;
      if (allReceives) break;
      if (!message.currentUserIsSender) {
        // Received Message
        if (!message.receiverSeen && !message.currentUserIsSender) {
          if (!notify && !fromOther) {
            // Notify Not Seen
            notify = true;
            _sendSeen();
          }
          message._see();
          change = true;
        }
      }
    }
    _allSeen = true;
    if (change) {
      notifyListeners();
      yazChatService._notify();
    }
    return;
  }

  Future<void> _sendSeen() async {
    await Future.delayed(Duration(milliseconds: 500));
    var data = {
      "time": DateTime.now().millisecondsSinceEpoch,
      CONVERSATION_ID: chatId,
      "starter_id": starter,
      "receiver_id": receiver
    };
    socketService.customOperation(SET_SEEN_DATA, data);
  }

  /// Handle Seen by other connection
  void _handleSeenReceives() {
    seeReceives(fromOther: true);
  }

  /// Handle send from other user
  void _handleNewMessage(YazChatMessage chatMessage) {
    _allSeen = false;
    messageList.add(chatMessage.conversationId, chatMessage);
    notifyListeners();
  }

  /// Handle send from other connection
  void _handleOwnMessage(YazChatMessage chatMessage) {
    _allSeen = false;
    messageList.add(chatMessage.conversationId, chatMessage);
    seeReceives();
  }

  /// Handle sent messages see by other user
  void _handleSee(DateTime time) {
    bool allSends = false, change = false;
    for (var message in messages!) {
      allSends = message.seenSent;
      if (allSends) break;
      if (time >= message.sendDate!) {
        // Sent before time
        if (message.currentUserIsSender) {
          message._see();
          change = true;
        }
      }
    }
    if (change) {
      notifyListeners();
      yazChatService._notify();
    }
    return;
  }

  void _update(YazChatConversation chatConversation) {
    this.totalMessageCount = chatConversation.totalMessageCount;
    this.lastActivity = chatConversation.lastActivity;
    _allSeen = false;
    notifyListeners();
  }

  final YazChatService yazChatService = YazChatService();

  Future<void> sendMessage(YazChatMessage message) async {
    messageList.add(message.conversationId, message);
    notifyListeners();
    yazChatService._notify();
    var op = await socketService
        .customOperation(SEND_MESSAGE_OPERATION, {"message": message.toJson()});
    if (op.isSuccess) {
      message.sendDate = DateTime.now();
      message._notifySend();
    }
  }
}
