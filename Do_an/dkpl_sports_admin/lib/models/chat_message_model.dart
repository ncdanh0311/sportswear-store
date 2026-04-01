class ChatMessageModel {
  final String text;
  final bool isOutgoing;
  final String time;
  final bool showProduct;
  final bool showVipBadge;
  final bool isTyping;

  const ChatMessageModel({
    required this.text,
    required this.isOutgoing,
    required this.time,
    this.showProduct = false,
    this.showVipBadge = false,
    this.isTyping = false,
  });
}
