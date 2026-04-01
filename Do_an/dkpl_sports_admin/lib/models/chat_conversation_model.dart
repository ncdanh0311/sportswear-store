class ChatConversationModel {
  final String name;
  final String initials;
  final String lastMessage;
  final String time;
  final int unread;
  final String source;
  final bool isVip;
  final int avatarColorHex;

  const ChatConversationModel({
    required this.name,
    required this.initials,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.source,
    required this.isVip,
    required this.avatarColorHex,
  });
}
