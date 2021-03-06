part of 'chat.dart';


class _ChatMessageWidget extends StatefulWidget {
  final YazChatMessage message;

  final Widget Function(YazChatMessage message) builder;

  const _ChatMessageWidget(
      {Key key, @required this.message, @required this.builder})
      : super(key: key);

  @override
  __ChatMessageWidgetState createState() => __ChatMessageWidgetState();
}

class __ChatMessageWidgetState extends State<_ChatMessageWidget> {
  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  bool listenerNeed;

  @override
  void initState() {
    listenerNeed = !widget.message.sent || !widget.message.receiverSeen;
    if (listenerNeed) widget.message.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    if (listenerNeed) widget.message.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeepAliveWidget( child: widget.builder(widget.message));
  }
}

class YazMessageListWidget extends StatefulWidget {
  YazMessageListWidget(
      {Key key,
      this.messageBuilder = _defaultMessageBuilder,
      this.sliverList = false,
      this.cacheExtend = 1000,
      this.itemExtend,
      this.scrollController,
      this.notSeenMessageCountListener,
      @required this.conversation})
      : super(key: key);

  static Widget _defaultMessageBuilder(YazChatMessage message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(message.content),
          )
        ],
      ),
    );
  }

  final YazChatConversation conversation;
  final Widget Function(YazChatMessage message) messageBuilder;
  final bool sliverList;

  final double cacheExtend;
  final double itemExtend;
  final ScrollController scrollController;

  final void Function(int count) notSeenMessageCountListener;

  @override
  _YazMessageListWidgetState createState() => _YazMessageListWidgetState();
}

class _YazMessageListWidgetState extends State<YazMessageListWidget> {
  ScrollController _scrollController;
  int _lastNotSeenMessageCount;

  void _listener() async {
    await Future.delayed(Duration(milliseconds: 30));
    if (mounted) {
      setState(() {});
    }
    if (widget.notSeenMessageCountListener != null) {
      var _mC = widget.conversation.notSeenMessageCount;
      if (_lastNotSeenMessageCount != _mC) {
        _lastNotSeenMessageCount = _mC;
        widget.notSeenMessageCountListener(_lastNotSeenMessageCount);
      }
    }
  }

  @override
  void initState() {
    _scrollController = widget.scrollController ?? ScrollController();
    widget.conversation.addListener(_listener);
    _lastNotSeenMessageCount = chatService.notSeenMessageCount;
    super.initState();
  }

  @override
  void dispose() {
    widget.conversation.removeListener(_listener);
    super.dispose();
  }

  Widget _builder(c, i) {
    if (i == widget.conversation.messageCount - 1) {
      widget.conversation.loadMore(() {
        setState(() {});
      });
    }

    return widget.messageBuilder(widget.conversation.messages[
        widget.sliverList ? widget.conversation.messageCount - i - 1 : i]);
  }

  final YazChatService chatService = YazChatService();

  @override
  Widget build(BuildContext context) {
    widget.conversation.build();
    return ListView.builder(
      itemBuilder: _builder,
      reverse: true,
      itemExtent: widget.itemExtend,
      cacheExtent: widget.cacheExtend,
      controller: _scrollController,
      itemCount: widget.conversation.messageCount,
    );
  }
}
