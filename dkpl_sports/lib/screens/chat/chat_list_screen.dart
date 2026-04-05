import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/product_repository.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(color: AppColors.textDark),
        ),
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: ProductRepository.loadProducts(),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];
          final chats = _buildFakeChats(products);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatListTile(
                title: chat.title,
                lastMessage: chat.lastMessage,
                time: chat.time,
                product: chat.product,
                unread: chat.unread,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        product: chat.product,
                        title: chat.title,
                        presetMessages: chat.presetMessages,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<_ChatItem> _buildFakeChats(List<ProductModel> products) {
    final product1 = products.isNotEmpty ? products[0] : null;
    final product2 = products.length > 1 ? products[1] : null;

    return [
      _ChatItem(
        title: 'DKPL Shop',
        lastMessage: 'Bạn cần hỗ trợ gì về đơn hàng?',
        time: '09:12',
        unread: 1,
        product: product1,
        presetMessages: [
          {'text': 'Mình muốn hỏi về chất liệu áo này.', 'isMe': true},
          {'text': 'Dạ áo dùng vải thun lạnh co giãn 4 chiều ạ.', 'isMe': false},
        ],
      ),
      _ChatItem(
        title: 'Chăm sóc khách hàng',
        lastMessage: 'Đơn hàng sẽ được giao trong 2-3 ngày.',
        time: 'Hôm qua',
        unread: 0,
        product: null,
        presetMessages: [
          {'text': 'Mình muốn đổi size.', 'isMe': true},
          {'text': 'Bạn vui lòng cung cấp mã đơn để mình hỗ trợ nhé.', 'isMe': false},
        ],
      ),
      _ChatItem(
        title: 'Tư vấn sản phẩm',
        lastMessage: 'Giày này có size 42 không ạ?',
        time: 'Th 2',
        unread: 0,
        product: product2,
        presetMessages: [
          {'text': 'Giày này có size 42 không ạ?', 'isMe': true},
          {'text': 'Dạ size 42 còn hàng nhé!', 'isMe': false},
        ],
      ),
    ];
  }
}

class _ChatItem {
  final String title;
  final String lastMessage;
  final String time;
  final int unread;
  final ProductModel? product;
  final List<Map<String, dynamic>> presetMessages;

  _ChatItem({
    required this.title,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.product,
    required this.presetMessages,
  });
}

class _ChatListTile extends StatelessWidget {
  final String title;
  final String lastMessage;
  final String time;
  final int unread;
  final ProductModel? product;
  final VoidCallback onTap;

  const _ChatListTile({
    required this.title,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (product == null) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.background,
        child: Icon(Icons.support_agent, color: AppColors.primaryBlue),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.background,
      backgroundImage: AssetImage(product!.image),
    );
  }
}
