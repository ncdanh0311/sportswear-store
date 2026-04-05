import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dkpl_sports_admin/models/chat_conversation_model.dart';
import 'package:dkpl_sports_admin/models/chat_message_model.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _threadId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<ChatConversationModel>> watchConversations({
    required String currentUserId,
    required String filter,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('chat_messages')
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final Map<String, ChatConversationModel> latestByUser = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = (data['senderId'] ?? '').toString();
        final receiverId = (data['receiverId'] ?? '').toString();
        final otherId = senderId == currentUserId ? receiverId : senderId;
        if (otherId.isEmpty) continue;

        if (!latestByUser.containsKey(otherId)) {
          final ts = data['createdAt'] as Timestamp?;
          final timeLabel = _formatConversationTime(ts?.toDate());
          latestByUser[otherId] = ChatConversationModel.fromComputed(
            id: _threadId(currentUserId, otherId),
            otherUserId: otherId,
            name: otherId,
            lastMessage: (data['content'] ?? '').toString(),
            time: timeLabel,
            lastMessageAt: ts?.toDate(),
          );
        }
      }

      return latestByUser.values.toList();
    });
  }

  Stream<List<ChatMessageModel>> watchMessages({
    required String currentUserId,
    required String otherUserId,
  }) {
    final threadId = _threadId(currentUserId, otherUserId);
    return _firestore
        .collection('chat_messages')
        .where('threadId', isEqualTo: threadId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final ts = doc.data()['createdAt'] as Timestamp?;
        final timeLabel = _formatMessageTime(ts?.toDate());
        return ChatMessageModel.fromFirestore(
          doc,
          currentUserId: currentUserId,
          timeLabel: timeLabel,
        );
      }).toList();
    });
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String text,
  }) async {
    final msgRef = _firestore.collection('chat_messages').doc();
    final now = FieldValue.serverTimestamp();

    final messageData = {
      'id': msgRef.id,
      'senderId': currentUserId,
      'receiverId': otherUserId,
      'content': text,
      'createdAt': now,
      'threadId': _threadId(currentUserId, otherUserId),
    };

    await msgRef.set(messageData);
  }

  String _formatConversationTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      return DateFormat('HH:mm').format(dt);
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    }
    return DateFormat('dd/MM').format(dt);
  }

  String _formatMessageTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }
}
