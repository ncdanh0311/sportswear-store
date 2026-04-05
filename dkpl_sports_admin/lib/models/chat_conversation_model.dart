class ChatConversationModel {
  final String id;
  final String name;
  final String initials;
  final String lastMessage;
  final String time;
  final int unread;
  final String source;
  final bool isVip;
  final int avatarColorHex;
  final DateTime? lastMessageAt;
  final String otherUserId;

  const ChatConversationModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.source,
    required this.isVip,
    required this.avatarColorHex,
    required this.lastMessageAt,
    required this.otherUserId,
  });

  factory ChatConversationModel.fromComputed({
    required String id,
    required String otherUserId,
    required String name,
    required String lastMessage,
    required String time,
    required DateTime? lastMessageAt,
  }) {
    final initials = name.isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join()
        : 'NA';

    return ChatConversationModel(
      id: id,
      name: name,
      initials: initials,
      lastMessage: lastMessage,
      time: time,
      unread: 0,
      source: 'Chat',
      isVip: false,
      avatarColorHex: 0xFF1877F2,
      lastMessageAt: lastMessageAt,
      otherUserId: otherUserId,
    );
  }
}
