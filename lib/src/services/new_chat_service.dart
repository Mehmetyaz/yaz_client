import 'package:flutter/cupertino.dart';
import 'package:yaz_client/src/services/chat_service.dart';

import '../../yaz_client.dart';

class NewChatService extends ChangeNotifier {
  factory NewChatService() => _instance;

  NewChatService._();

  static final NewChatService _instance = NewChatService._();

  Chat operator [](String chatId) {
    return _conversations[chatId];
  }

  int get notificationCount {
    int i = 0;
    var res = 0;

    while (i < conversationsIds.length) {
      // if (_conversations[conversationsIds[i]].messages.isNotEmpty &&
      //     _conversations[conversationsIds[i]].messages[0].seenByOwn) {
      //   return res;
      // }

      res += _conversations[conversationsIds[i]] != null
          ? _conversations[conversationsIds[i]].notSeenMessageCount
          : 0;

      i++;
    }

    return res;
  }

  _createIfNotExists() {
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
  }

  Future<List<Chat>> _getAllConversations() async {
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

    return (chatListData).map<Chat>((e) => Chat.fromJson(e)).toList();
  }

  _addReceivedNewConversation(String chatId) async {
    try {
      _conversations[chatId] = Chat.fromJson(
          (await socketService.query(Query.create("conversations", equals: {
        "chat_id": chatId,
      })))
              .data);
      conversationsIds.insert(0, chatId);
      _sort();
      notifyListeners();
    } catch (e) {}
  }


  _listen() {
    socketService.listenChat((data) async {
      if (data["type"] != null) {
        switch (data["type"]) {
          case "new_message":
            if (!_conversations.containsKey(data["chat_id"])) {
              await _addReceivedNewConversation(data["chat_id"]);
            }

            print("NEW MESSAGE RECEIVED : ${data.data}");


            _conversations[data["chat_id"]]
                .addNewMessage(ChatMessage.fromJson(data.data));
            _sort();
            notifyListeners();
            break;
          case "message_seen":
            var chat = data["chat_id"] as String;
            _conversations[chat].updateSeenReceived(data);
            break;
        }
      }
    });
  }

  seen(String chatId) {
    socketService.customOperation("set_seen", {"chat_id": chatId});
  }

  _sort() {
    /// Sort desc
    conversationsIds
        .sort((a, b) => _conversations[b].compareTo(_conversations[a]));
  }

  Future<void> init() async {
    if (!authService.isLoggedIn) {
      print("WARNING: Load Chats calling when auth is not logged in");
      return null;
    }
    _createIfNotExists();

    var _initialList = await _getAllConversations();

    /// Sort Descending
    _initialList.sort((a, b) => b.compareTo(a));

    /// add descending
    conversationsIds.addAll(_initialList.map((e) => e.chatId));

    _conversations.addEntries(_initialList
        .map<MapEntry<String, Chat>>((e) => MapEntry(e.chatId, e))
        .toList());

    var ftrs = <Future<void>>[];

    ftrs.addAll(_conversations.values.map((e) => e.cache()));

    await Future.wait(ftrs);

    _listen();

    /// Adding initial completed
    ///
    return;
  }

  final List<String> conversationsIds = <String>[];

  final Map<String, Chat> _conversations = <String, Chat>{};

  Future<bool> sendMessage(ChatMessage message) async {
    _conversations[message.chatId].addNewMessage(message);
    var res = await socketService
        .customOperation("send_message", {"message": message}, useToken: true);
    message.sent = res.isSuccess;
    _sort();
    notifyListeners();
    return res.isSuccess;
  }

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
      conversationsIds.insert(0, chat.chatId);
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
    conversationsIds.insert(0, chat.chatId);
    notifyListeners();
    return chat;
  }

  final MessageList messageList = MessageList();
}
