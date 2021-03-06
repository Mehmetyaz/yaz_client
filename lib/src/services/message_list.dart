

import 'chat/chat.dart';

class MessageList {
  ///
  factory MessageList() => _instance;

  ///
  MessageList._internal();

  ///
  static final MessageList _instance = MessageList._internal();

  /// Sorted descending
  final Map<String, List<YazChatMessage>> messages =
      <String, List<YazChatMessage>>{};

  void addAll(String chatID, List<YazChatMessage> _messages,
      {bool last = false}) {
    /// descend for inserting
    _messages.sort((a, b) => b.compareTo(a));

    messages[chatID] ??= <YazChatMessage>[];
    messages[chatID].insertAll(last ? messages[chatID].length : 0, _messages);
  }

  void add(String chatID, YazChatMessage _message, {bool last = false}) {
    messages[chatID] ??= <YazChatMessage>[];
    messages[chatID].insert(last ? messages[chatID].length : 0, _message);
  }

  List<YazChatMessage> operator [](String chatID) {
    return messages[chatID];
  }
}
