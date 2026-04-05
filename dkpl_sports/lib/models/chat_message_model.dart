import 'model_utils.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: (map['id'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      createdAt: ModelUtils.readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
