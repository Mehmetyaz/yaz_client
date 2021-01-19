import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaz_client/src/models/chat.dart';
import 'package:yaz_client/src/models/chat_message.dart';
import 'package:yaz_client/src/services/new_chat_service.dart';
import 'package:yaz_client/yaz_client.dart';

class MessageList {
  ///
  factory MessageList() => _instance;

  ///
  MessageList._internal();

  ///
  static final MessageList _instance = MessageList._internal();

  /// Sorted descending
  final Map<String, List<ChatMessage>> messages = <String, List<ChatMessage>>{};

  void addAll(String chatID, List<ChatMessage> _messages, {bool last = false}) {
    /// descend for inserting
    _messages.sort((a, b) => b.compareTo(a));

    messages[chatID] ??= <ChatMessage>[];
    messages[chatID].insertAll(last ? messages[chatID].length : 0, _messages);
  }

  void add(String chatID, ChatMessage _message, {bool last = false}) {
    messages[chatID] ??= <ChatMessage>[];
    messages[chatID].insert(last ? messages[chatID].length : 0, _message);
  }

  List<ChatMessage> operator [](String chatID) {
    return messages[chatID];
  }
}

NewChatService chatService = NewChatService();

///
class ChatService extends ChangeNotifier {
  ///
  factory ChatService() => _instance;

  ///
  ChatService._internal();

  ///
  static final ChatService _instance = ChatService._internal();

  List<String> _messageTypes = <String>["picture", "text"];

  void setOptions({List<String> additionalMessageTypes}) {
    if (additionalMessageTypes != null && additionalMessageTypes.isNotEmpty) {
      _messageTypes.addAll(additionalMessageTypes);
    }
  }

  void setLastSeen(Chat chat) {
    socketService.customOperation("set_seen", {"chat_id": chat.chatId});

    // if (chat.isStarter) {
    //   chat.lastActivitySeenSender = DateTime.now().millisecondsSinceEpoch;
    // } else {
    //   chat.lastActivitySeenReceiver = DateTime.now().millisecondsSinceEpoch;
    // }
    // socketService.updateDocument(Query.create("conversations", equals: {
    //   "chat_id": chat.chatId,
    // }, update: {
    //   "\$set": chat.isStarter
    //       ? {"last_activity_seen_sender": DateTime.now().millisecondsSinceEpoch}
    //       : {
    //           "last_activity_seen_receiver":
    //               DateTime.now().millisecondsSinceEpoch
    //         }
    // }));
    // notifyListeners();
  }

  /// Total Notification Count
  int get notificationCount {
    var i = 0;
    for (var c in _conversations.values) {
      var notS = c.notSeenMessageCount;
      i += notS;
      if (notS == 0) break;
    }
    return i;
  }

  Map<String, Chat> _conversations = <String, Chat>{};

  List<String> _sortedConversations = <String>[];

  int get count {
    return _conversations.length;
  }

  Chat getConversations(int i) {
    return _conversations[_sortedConversations[i]];
  }

  bool chatPageOpened = false;

  void _listen() {
    // socketService.listenChat((event) {
    //   if (event["new_messages"] != null &&
    //       (event["new_messages"] as List).isNotEmpty) {
    //     print("2 çalıştı");
    //     for (var conv
    //     in event["new_messages"].map<Chat>((e) => Chat.fromJson(e))) {
    //       if (_conversations[conv.chatId] != null) {
    //         _conversations[conv.chatId].update(conv);
    //       } else {
    //         _conversations[conv.chatId] = conv;
    //       }
    //     }
    //
    //     _setSorted();
    //
    //     // socketService
    //     //     .updateDocument(Query.create("user_chat_documents", equals: {
    //     //   "user_id": authService.userID
    //     // }, update: {
    //     //   "\$set": {"new_messages": <String>[]}
    //     // }));
    //     notifyListeners();
    //   } else if (event["chat_id"] != null &&
    //       event["last_activity_seen_sender"] != null &&
    //       event["last_activity_seen_receiver"] != null &&
    //       _conversations[event["chat_id"]] != null) {
    //     print("1 çalıştı");
    //
    //
    //     if ( _conversations[event["chat_id"]].isStarter){
    //       _conversations[event["chat_id"]]
    //         ..lastActivitySeenSender = event["last_activity_seen_sender"];
    //     } else {
    //       _conversations[event["chat_id"]]
    //         ..lastActivitySeenReceiver = event["last_activity_seen_receiver"];
    //     }
    //
    //     _setSorted();
    //     notifyListeners();
    //   }
    // });
  }

  ///
  Future<void> init() async {
    if (!authService.isLoggedIn) {
      print("WARNING: Load Chats calling when auth is not logged in");
      return null;
    }
    socketService
        .exists(Query.create("user_chat_documents",
            equals: {"user_id": authService.userID}))
        .then((value) {
      print(value);
      if (value == null || (value != null && !value)) {
        socketService.insertQuery(Query.create("user_chat_documents",
            document: {"user_id": authService.userID}));
      }
    });

    // var sharedPrefFtr = SharedPreferences.getInstance();
    //
    // var sharedPref = await sharedPrefFtr;
    //
    // for (var c in (sharedPref
    //     .getStringList("conversations") ?? <String>[])
    //     .map<Chat>((e) => Chat.fromJson(json.decode(e)))) {
    //   _conversations[c.chatId] = c;
    // }

    // var lastChatLoaded = _conversations.length > 1
    //     ? _conversations[_conversations.keys.first].lastActivity.millisecondsSinceEpoch
    //     : 0;

    /// get_conversations :
    ///   bu tarihen itbaren tüm yeni mesajları chatler halinde getirir
    var chatListData =
        await socketService.listQuery(Query.create("conversations", equals: {
      "starter_id": authService.userID,
    }, sorts: <String, Sorting>{
      "last_activity": Sorting.descending
    }));

    var chatListData2 =
        await socketService.listQuery(Query.create("conversations", equals: {
      "receiver_id": authService.userID,
    }, sorts: <String, Sorting>{
      "last_activity": Sorting.descending
    }));

    print("CHAT LIST DATA :  :  : $chatListData");

    chatListData.addAll(chatListData2);

    var chatList = (chatListData).map<Chat>((e) => Chat.fromJson(e)).toList();

    await _addChatsLocal(chatList);

    _listen();

    /// Checked local doc- chat doc for new conversation
  }

  void _setSorted() {
    _sortedConversations = _conversations.keys.toList();
    _sortedConversations
        .sort((a, b) => _conversations[b].compareTo(_conversations[a]));
  }

  Future<void> _addChatsLocal(List<Chat> chats) async {
    // for (var conv in chats) {
    //   if (_conversations[conv.chatId] != null) {
    //     _conversations[conv.chatId].update(conv);
    //   } else {
    //     _conversations[conv.chatId] = conv;
    //   }
    //   await _conversations[conv.chatId].cache();
    // }

    // var shared = await SharedPreferences.getInstance();
    // shared.setStringList(
    //     "conversations",
    //     _conversations.entries
    //         .map((e) => json.encode(e.value.toJson()))
    //         .toList());
    _setSorted();
    notifyListeners();
  }

  // Future<void> _setLocal() async {
  //   var shared = await SharedPreferences.getInstance();
  //   shared.setStringList(
  //       "conversations",
  //       _conversations.entries
  //           .map((e) => json.encode(e.value.toJson()))
  //           .toList());
  // }

  Future<bool> sendMessage(ChatMessage message) async {
    _conversations[message.chatId].addNewMessage(message);
    var res = await socketService
        .customOperation("send_message", {"message": message}, useToken: true);
    message.sent = res.isSuccess;
    _setSorted();
    notifyListeners();
    return res.isSuccess;
  }

  ///
  Future<Chat> startChat(String userWith) async {
    var _id = Statics.getRandomId(30);

    var ex = _conversations.values.where((element) => element.isStarter
        ? element.receiver == userWith
        : element.starter == userWith);

    if (ex.isNotEmpty) return ex.first;

    var existStarted = socketService.exists(Query.create("conversations",
        equals: {"starter_id": authService.userID}));

    var existsReceived = socketService.exists(Query.create("conversations",
        equals: {"receiver_id": authService.userID}));

    var l = [await existStarted, await existsReceived];

    if (l.contains(true)) {
      var chat = Chat.fromJson((await socketService.query(Query.create(
              "conversations",
              equals: await existsReceived
                  ? {"receiver_id": authService.userID}
                  : {"starter_id": authService.userID})))
          .data);

      print("ON MESSAGE:  :  : : :: : : ${chat.toJson()}");

      _conversations[chat.chatId] = chat;
      _setSorted();
      return chat;
    }

    var chatJson = await socketService.customOperation(
        "start_chat",
        {
          "receiver": userWith,
          "chat_id": _id,
        },
        useToken: true);

    var chat = Chat.fromJson(chatJson.data["document"]["ops"][0]);
    _conversations[chat.chatId] = chat;
    _sortedConversations.insert(0, chat.chatId);
    _addChatsLocal([chat]);
    notifyListeners();
    return chat;
  }
}
