import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'chat_detail_screen.dart';
import 'package:dkpl_sports_admin/models/chat_conversation_model.dart';

final _conversations = [
  const ChatConversationModel(
    name: 'Nguyễn Thị Lan',
    initials: 'NL',
    lastMessage: 'Áo polo này còn size L màu đen không ạ?',
    time: '14:23',
    unread: 2,
    source: 'Facebook',
    isVip: true,
    avatarColorHex: 0xFF1877F2,
  ),
  const ChatConversationModel(
    name: 'Trần Văn Minh',
    initials: 'TM',
    lastMessage: 'Shop giao hàng bao lâu vậy ạ',
    time: '13:45',
    unread: 1,
    source: 'TikTok',
    isVip: false,
    avatarColorHex: 0xFF00D4FF,
  ),
  const ChatConversationModel(
    name: 'Lê Thị Hoa',
    initials: 'LH',
    lastMessage: 'Cho mình đổi size được không ạ?',
    time: '12:10',
    unread: 3,
    source: 'Facebook',
    isVip: true,
    avatarColorHex: 0xFFA78BFA,
  ),
  const ChatConversationModel(
    name: 'Phạm Quốc Tuấn',
    initials: 'PT',
    lastMessage: 'OK shop ơi mình đặt 2 cái nhé',
    time: '11:30',
    unread: 0,
    source: 'TikTok',
    isVip: false,
    avatarColorHex: 0xFF00E5A0,
  ),
  const ChatConversationModel(
    name: 'Ngô Thị Thu',
    initials: 'NT',
    lastMessage: 'Quần jogger còn màu xám không shop?',
    time: '10:55',
    unread: 1,
    source: 'Facebook',
    isVip: false,
    avatarColorHex: 0xFFFFB347,
  ),
  const ChatConversationModel(
    name: 'Đỗ Văn Khải',
    initials: 'DK',
    lastMessage: 'Cảm ơn shop, mình nhận được rồi ạ!',
    time: 'Hôm qua',
    unread: 0,
    source: 'TikTok',
    isVip: true,
    avatarColorHex: 0xFF1877F2,
  ),
];

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _filter = 'Tất cả';
  final _filters = ['Tất cả', 'Chưa rep', 'VIP', 'Facebook', 'TikTok'];

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text('Rep CMT Khách'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter chips
          _buildFilterRow(),
          // Stats bar
          _buildStatsBar(),
          // List
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isActive = _filter == _filters[i];
          return GestureDetector(
            onTap: () => setState(() => _filter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accentCyan.withOpacity(0.15)
                    : Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive 
                      ? AppColors.accentCyan.withOpacity(0.4)
                      : Color(0x1AFFFFFF),
                ),
              ),
              child: Center(
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.accentCyan
                        : AppColors.textSecondary,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          _StatChip(label: 'Chờ rep', value: '7', color: Color(0xFFFF5252)),
          const SizedBox(width: 12),
          _StatChip(label: 'Hôm nay', value: '24', color: Color(0xFF00E5A0)),
          const SizedBox(width: 12),
          _StatChip(label: 'Đã chốt', value: '18', color: Color(0xFF00E5A0)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentCyan, AppColors.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'AI hỗ trợ ON',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => Divider(
        color: Color(0xFFE0E0E0),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final c = _conversations[index];
        return _ConversationTile(
          item: c,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                customerName: c.name,
                customerInitials: c.initials,
                source: c.source,
                isVip: c.isVip,
                avatarColor: Color(c.avatarColorHex),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversationModel item;
  final VoidCallback onTap;

  const _ConversationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(item.avatarColorHex),
                        Color(item.avatarColorHex).withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
                if (item.isVip)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('★', style: TextStyle(fontSize: 8, color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _SourceBadge(source: item.source),
                      const Spacer(),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.lastMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: item.unread > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: item.unread > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentCyan, AppColors.primaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.unread}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isFb = source == 'Facebook';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isFb ? const Color(0xFF1877F2) : AppColors.accentCyan)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source == 'Facebook' ? 'FB' : 'TT',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isFb ? const Color(0xFF1877F2) : AppColors.accentCyan,
        ),
      ),
    );
  }
}

