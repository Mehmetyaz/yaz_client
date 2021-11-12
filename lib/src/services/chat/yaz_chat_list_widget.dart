part of 'chat.dart';

class _ChatCardWidget<T> extends StatefulWidget {
  final Widget Function(YazChatConversation? conversation, T userInfo) builder;

  final YazChatConversation? conversation;

  final T? userInfo;

  const _ChatCardWidget({
    Key? key,
    required this.builder,
    this.conversation,
    this.userInfo,
  }) : super(key: key);

  @override
  __ChatCardWidgetState<T> createState() => __ChatCardWidgetState<T>();
}

class __ChatCardWidgetState<T> extends State<_ChatCardWidget<T?>> {
  _listener() async {
    await Future.delayed(Duration(milliseconds: 50));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    widget.conversation!.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    widget.conversation!.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeepAliveWidget(
        child: widget.builder(widget.conversation, widget.userInfo));
  }
}

class YazChatListWidget<T> extends StatefulWidget {
  YazChatListWidget(
      {Key? key,
      required this.conversationCardBuilder,
      required this.userInfoLoader,
      this.sliverList = false,
      this.placeHolderBuilder = _defaultBuilder,
      this.errorBuilder = _defaultErrorBuilder,
      this.cacheExtend = 3000,
      this.itemExtend,
      this.scrollController,
      this.notSeenMessageCountListener})
      : super(key: key);

  static Widget _defaultBuilder(BuildContext context, String? id, int index) {
    return SizedBox(
      height: 30,
      width: 30,
    );
  }

  static Widget _defaultErrorBuilder(
      BuildContext context, String? id, int index) {
    return SizedBox(
      height: 30,
      width: 30,
    );
  }

  final Widget Function(YazChatConversation? conversation, T userInfo)
      conversationCardBuilder;

  final Widget Function(BuildContext context, String? id, int index)
      placeHolderBuilder;
  final Widget Function(BuildContext context, String? id, int index)
      errorBuilder;

  final Future<T> Function(String userId) userInfoLoader;

  final bool sliverList;

  final double cacheExtend;
  final double? itemExtend;
  final ScrollController? scrollController;

  final void Function(int? count)? notSeenMessageCountListener;

  @override
  _YazChatListWidgetState<T> createState() => _YazChatListWidgetState<T>();
}

class _YazChatListWidgetState<T> extends State<YazChatListWidget<T>> {
  late ScrollController _scrollController;

  Map<String, T> users = <String, T>{};

  Widget _res(YazChatConversation conversation) {
    return _ChatCardWidget(
      builder: widget.conversationCardBuilder,
      conversation: conversation,
      userInfo: users[conversation.otherId],
    );
  }

  Future<T> _infoLoader(String id) async {
    T _r = await widget.userInfoLoader(id);
    users[id] = _r;
    return _r;
  }

  Widget _buildCard(int index) {
    var id = chatService._conversationsIds[index];
    var conversation = chatService._conversations[id]!;
    var userLoaded = users.containsKey(conversation.otherId);
    if (userLoaded) return _res(conversation);
    return FutureBuilder<T>(
        future: _infoLoader(conversation.otherId),
        builder: (c, AsyncSnapshot<T> snap) {
          if (snap.hasError) {
            return widget.errorBuilder(c, conversation.otherId, index);
          }

          if (snap.connectionState == ConnectionState.none) {
            return widget.errorBuilder(c, conversation.otherId, index);
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return widget.placeHolderBuilder(c, conversation.otherId, index);
          }
          return _res(conversation);
        });
  }

  Widget _builder(BuildContext c, int i) {
    return _buildCard(i);
  }

  int? _lastNotSeenMessageCount;

  @override
  void initState() {
    _scrollController = widget.scrollController ?? ScrollController();
    chatService.addListener(_listener);
    _lastNotSeenMessageCount = chatService.notSeenMessageCount;
    super.initState();
  }

  _listener() async {
    await Future.delayed(Duration(milliseconds: 50));
    if (mounted) {
      setState(() {});
    }

    if (widget.notSeenMessageCountListener != null) {
      var _mC = chatService.notSeenMessageCount;
      if (_lastNotSeenMessageCount != _mC) {
        _lastNotSeenMessageCount = _mC;
        widget.notSeenMessageCountListener!(_lastNotSeenMessageCount);
      }
    }
  }

  @override
  void dispose() {
    chatService.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.sliverList
        ? SliverList(
            delegate: SliverChildBuilderDelegate(_builder,
                childCount: chatService._conversationsIds.length,
                addAutomaticKeepAlives: true))
        : ListView.builder(
            itemCount: chatService._conversationsIds.length,
            cacheExtent: widget.cacheExtend,
            controller: _scrollController,
            itemExtent: widget.itemExtend,
            itemBuilder: _builder);
  }
}
