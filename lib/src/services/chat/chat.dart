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
  final List<String?> _conversationsIds = <String?>[];

  Future<YazChatConversation> startChat(String userWith) async {
    var _id = Statics.getRandomId(30);

    var ex = _conversations.values.where((element) => element.isStarter
        ? element.receiver == userWith
        : element.starter == userWith);

    if (ex.isNotEmpty) return ex.first;

    var existStarted = socketService.exists(Query.create(CHAT_COLLECTIONS,
        equals: {"starter_id": authService.userID}));

    var existsReceived = socketService.exists(Query.create(CHAT_COLLECTIONS,
        equals: {"receiver_id": authService.userID}));

    var l = [await existStarted, await existsReceived];

    if (l.contains(true)) {
      var newChatMe = await socketService.query(Query.create(CHAT_COLLECTIONS,
          equals: (await existsReceived)!
              ? {"receiver_id": authService.userID}
              : {"starter_id": authService.userID}));

      print("STARTING CHAT: ${newChatMe.data}");

      var chat = YazChatConversation.fromJson((newChatMe).data!);

      print("ON MESSAGE:  :  : : :: : : ${chat.toJson()}");

      _conversations[chat.chatId] = chat;
      _conversationsIds.insert(0, chat.chatId);
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
    _conversationsIds.insert(0, chat.chatId);
    notifyListeners();
    return chat;
  }

  _sort() {
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
              print("DDDD0");
              // print(_conversations[_conId].toJson());
              print("DDDD1");
              await _addReceivedNewConversation(
                  YazChatConversation.fromJson(data["conversation_data"]));
            }
            print("NEW MESSAGE RECEIVED : ${data.data}");
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
              .._handleOwnMessage(YazChatMessage.fromJson(data.data!["message"]))
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
      _conversationsIds.insert(0, conversation.chatId);
      _sort();
      notifyListeners();

      return;
    } catch (e) {
      print("CHAT DOC ALINAMADI : $e");
    }
  }

  Future<List<YazChatConversation>> _getAllConversations() async {
    var chatListData =
        await socketService.listQuery(Query.create(CHAT_COLLECTIONS, equals: {
      "starter_id": authService.userID,
    }, sorts: <String, Sorting>{
      LAST_ACTIVITY: Sorting.descending
    }));

    var chatListData2 =
        await socketService.listQuery(Query.create(CHAT_COLLECTIONS, equals: {
      "receiver_id": authService.userID,
    }, sorts: <String, Sorting>{
      LAST_ACTIVITY: Sorting.descending
    }));

    print("CHAT LIST DATA :  :  : $chatListData");

    chatListData.addAll(chatListData2);

    return (chatListData)
        .map<YazChatConversation>((e) => YazChatConversation.fromJson(e!))
        .toList();
  }

  // _createIfNotExists() {
  //   socketService
  //       .exists(Query.create("user_chat_documents",
  //       equals: {"user_id": authService.userID}))
  //       .then((value) {
  //     print(value);
  //     if (value == null || (value != null && !value)) {
  //       socketService.insertQuery(Query.create("user_chat_documents",
  //           document: {"user_id": authService.userID}));
  //     }
  //   });
  // }

  Future<void> init() async {
    if (!authService.isLoggedIn) {
      print("WARNING: Load Chats calling when auth is not logged in");
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
  YazChatMessage(this.senderId, this.receiverId, this.messageId, this.content,
      this.type, this.conversationId)
      : sent = true;

  factory YazChatMessage.fromJson(Map<String, dynamic> map) =>
      _$YazChatMessageFromJson(map);

  Map<String, dynamic> toJson() => _$YazChatMessageToJson(this);

  YazChatMessage.create(this.content,
      {this.type = "text", required YazChatConversation chatConversation})
      : conversationId = chatConversation.chatId,
        receiverSeen = false,
        receiverId = chatConversation.otherId,
        senderId = chatConversation.ownId,
        sendDate = DateTime.now(),
        messageId = Statics.getRandomId(20);
  @JsonKey(ignore: true)
  late bool sent;

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
  final String? senderId;

  @JsonKey(name: "receiver_id", required: true)
  final String? receiverId;

  @JsonKey(name: "receiver_seen", required: true)
  bool? receiverSeen;

  @JsonKey(name: "message_id")
  final String? messageId;

  @JsonKey(name: "message_content")
  final String? content;

  @JsonKey(name: "message_type")
  final String? type;

  @JsonKey(name: CONVERSATION_ID)
  final String? conversationId;

  bool get currentUserIsSender {
    // print("CurrentUSER: ${authService.currentUser}");
    // print(authService.currentUser.toJson());
    return authService.currentUser!.userID == senderId;
  }

  bool get seenReceived {
    return !currentUserIsSender && receiverSeen!;
  }

  bool get seenSent {
    return currentUserIsSender && receiverSeen!;
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

@JsonSerializable()
class YazChatConversation extends Comparable with ChangeNotifier {
  YazChatConversation(this.chatId, this.starter, this.receiver);

  factory YazChatConversation.fromJson(Map<String, dynamic> json) =>
      _$YazChatConversationFromJson(json);

  Map<String, dynamic> toJson() => _$YazChatConversationToJson(this);

  @JsonKey(name: CONVERSATION_ID, required: true)
  final String? chatId;

  @JsonKey(name: "starter_id", required: true)
  final String? starter;

  @JsonKey(name: "receiver_id", required: true)
  final String? receiver;

  @JsonKey(ignore: true)
  final MessageList messageList = MessageList();

  @JsonKey(
    name: LAST_ACTIVITY,
    fromJson: UserModelStatics.dateFromJson,
    toJson: UserModelStatics.dateToInt,
  )
  DateTime? lastActivity;

  @JsonKey(ignore: true)
  List<YazChatMessage>? get messages {
    return messageList[chatId];
  }

  @JsonKey(ignore: true)
  YazChatMessage? get lastMessage {
    if (messageList[chatId] != null && messageList[chatId]!.isEmpty) {
      return null;
    }

    return (messageList[chatId] ?? []).first;
  }

  @JsonKey(ignore: true)
  bool get isEmpty {
    return messageList[chatId]!.isEmpty;
  }

  @override
  int compareTo(other) {
    // TODO: implement compareTo
    throw UnimplementedError();
  }

  Future<void> _cache() async {
    var list = await socketService.listQuery(Query.create(MESSAGE_COLLECTION,
        sorts: <String, Sorting>{
          MESSAGE_TIME: Sorting.descending,
        },
        equals: {CONVERSATION_ID: chatId},
        limit: 5));
    messageList.addAll(chatId,
        list.map<YazChatMessage>((e) => YazChatMessage.fromJson(e!)).toList());

    _allSeen = messages!.any((element) => !element.receiverSeen!);
    print("ALL SEEN SETTET: ${_allSeen}");
    return null;
  }

  @JsonKey(ignore: true)
  bool hasMore = true;

  @JsonKey(ignore: true)
  bool loaded = false;

  @JsonKey(ignore: false, required: true, name: "total_message_count")
  int? totalMessageCount;

  @JsonKey(ignore: true)
  int get messageCount {
    return (messageList[chatId] ?? []).length;
  }

  loadMore(Function onLoad) async {
    _allSeen = false;
    print("LOAD MORE");
    if (!loaded && hasMore) {
      if (totalMessageCount! > messageCount) {
        loaded = true;
        notifyListeners();
        var _nMessages = await socketService
            .listQuery(Query.create(MESSAGE_COLLECTION, limit: 100, filters: {
          "lt": {
            MESSAGE_TIME:
                messageList[chatId]!.last.sendDate!.millisecondsSinceEpoch
          }
        }, equals: {
          CONVERSATION_ID: chatId
        }));

        if (_nMessages.length == 0) {
          hasMore = false;
        }

        messageList.addAll(
            chatId,
            _nMessages
                .map<YazChatMessage>((e) => YazChatMessage.fromJson(e!))
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

  String? get otherId {
    return isStarter ? receiver : starter;
  }

  String? get ownId {
    return isStarter ? starter : receiver;
  }

  @JsonKey(ignore: true)
  int get notSeenMessageCount {
    int res = 0;
    for (var message in (messageList[chatId] ?? [])
        .where((element) => !element.currentUserIsSender)) {
      if (!message.receiverSeen!) {
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
        print("${message.content} currentReceiver");
        // Received Message
        if (!message.receiverSeen! && !message.currentUserIsSender) {
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
    print("Message: ${message.toJson()}");
    messageList.add(message.conversationId, message);
    notifyListeners();
    yazChatService._notify();
    var op = await socketService
        .customOperation(SEND_MESSAGE_OPERATION, {"message": message.toJson()});
    if (op.isSuccess!) {
      message._notifySend();
    }
  }
}
