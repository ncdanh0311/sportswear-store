import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime? createdAt;

  final bool isOutgoing;
  final String time;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isOutgoing,
    required this.time,
  });

  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
    required String timeLabel,
  }) {
    final data = doc.data() ?? {};
    final senderId = ModelUtils.readString(data['senderId']);
    return ChatMessageModel(
      id: doc.id,
      senderId: senderId,
      receiverId: ModelUtils.readString(data['receiverId']),
      content: ModelUtils.readString(data['content']),
      createdAt: ModelUtils.readDateTime(data['createdAt']),
      isOutgoing: senderId == currentUserId,
      time: timeLabel,
    );
  }
}
