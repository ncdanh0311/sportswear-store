import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/chat_message_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final String customerName;
  final String customerInitials;
  final String source;
  final bool isVip;
  final Color avatarColor;

  const ChatDetailScreen({
    super.key,
    required this.customerName,
    required this.customerInitials,
    required this.source,
    required this.isVip,
    required this.avatarColor,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showAiSuggest = true;
  bool _isTyping = false;

  final _aiSuggestion =
      'Dạ chị là khách VIP nên mua 2 sẽ được giảm 10% còn 531,000₫ ạ. Shop tặng thêm tất nam nữa chị nhé! 🎁';

  late List<ChatMessageModel> _messages;

  final _quickReplies = [
    'Còn hàng ✓',
    'Giảm 10% VIP',
    'Gửi link đặt hàng',
    'Tạo đơn ngay',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      const ChatMessageModel(
        text: 'Cho mình hỏi áo polo này còn size L màu đen không ạ? 😊',
        isOutgoing: false,
        time: '14:23',
      ),
      const ChatMessageModel(
        text: 'Dạ chào chị! Áo Polo Nam Slim Fit màu đen size L hiện vẫn còn hàng ạ 🎉',
        isOutgoing: true,
        time: '14:25',
        showProduct: true,
      ),
      const ChatMessageModel(
        text: 'Nếu mình mua 2 cái có được giảm giá không ạ? Chị thường mua ở shop hay lắm',
        isOutgoing: false,
        time: '14:27',
        showVipBadge: true,
      ),
    ];

    // Simulate typing after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isTyping = true);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessageModel(
        text: text.trim(),
        isOutgoing: true,
        time: _currentTime(),
      ));
      _isTyping = false;
      _showAiSuggest = false;
    });
    _textController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _currentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.mainGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Context banner
            _buildContextBanner(),
            // Tab bar
            _buildTabBar(),
            // Messages
            Expanded(child: _buildMessageList()),
            // AI Suggest
            if (_showAiSuggest) _buildAiSuggest(),
            // Quick replies
            _buildQuickReplies(),
            // Input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            widget.customerName,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSourceDot(const Color(0xFF1877F2)),
              const SizedBox(width: 4),
              const Text(
                'Facebook',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const Text(
                ' • ',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              _buildSourceDot(AppColors.accentCyan),
              const SizedBox(width: 4),
              const Text(
                'TikTok Shop',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _IconBtn(icon: Icons.assignment_outlined, onTap: () {}),
        _IconBtn(icon: Icons.more_horiz_rounded, onTap: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSourceDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildContextBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('🛒', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khách đang hỏi về Áo Polo Nam DKPL Slim Fit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentCyan,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phát hiện từ comment #FB-2847 · 10 phút trước',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color:Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          _TabBtn(label: '💬 Chat', isActive: true, onTap: () {}),
          _TabBtn(label: '📦 Đơn hàng (3)', isActive: false, onTap: () {}),
          _TabBtn(label: '👤 Hồ sơ', isActive: false, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 2 : 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _DateDivider(label: 'Hôm nay, 14:23');
        }
        final msgIndex = index - 1;
        if (_isTyping && msgIndex == _messages.length) {
          return _TypingBubble(
            avatarColor: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.accentCyan],
            ),
          );
        }
        final msg = _messages[msgIndex];
        return _MessageRow(
          msg: msg,
          customerInitials: widget.customerInitials,
          customerAvatarColor: widget.avatarColor,
          isVip: widget.isVip,
        );
      },
    );
  }

  Widget _buildAiSuggest() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentCyan.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                children: [
                  const TextSpan(
                    text: 'AI gợi ý: ',
                    style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: _aiSuggestion),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _textController.text = _aiSuggestion;
              setState(() => _showAiSuggest = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
              ),
              child: const Text(
                'Dùng',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _textController.text = _quickReplies[i],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  _quickReplies[i],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentCyan,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF001233).withOpacity(0.9),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach
          _IconBtn(icon: Icons.attach_file_rounded, onTap: () {}),
          const SizedBox(width: 10),
          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 100),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBlue),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Color(0x59FFFFFF), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onChanged: (v) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accentCyan, AppColors.primaryBlue],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────── SUB WIDGETS ───────────

class _DateDivider extends StatelessWidget {
  final String label;
  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Color(0x1AFFFFFF))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Divider(color: Color(0x1AFFFFFF))),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessageModel msg;
  final String customerInitials;
  final Color customerAvatarColor;
  final bool isVip;

  const _MessageRow({
    required this.msg,
    required this.customerInitials,
    required this.customerAvatarColor,
    required this.isVip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isOutgoing) ...[
            _Avatar(
              initials: customerInitials,
              color: customerAvatarColor,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isOutgoing
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    gradient: msg.isOutgoing
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.accentCyan, AppColors.primaryBlue],
                          )
                        : null,
                    color: msg.isOutgoing ? null : Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(msg.isOutgoing ? 18 : 4),
                      bottomRight: Radius.circular(msg.isOutgoing ? 4 : 18),
                    ),
                    border: msg.isOutgoing
                        ? null
                        : Border.all(color: Color(0x1AFFFFFF)),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                // Product card
                if (msg.showProduct)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentCyan.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryBlue, AppColors.primaryNavy],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('👕', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Áo Polo Nam DKPL Slim Fit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '295,000₫ · Còn 12 cái',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accentCyan,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // VIP badge
                if (msg.showVipBadge && isVip)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      '🏆 Khách VIP · 8 đơn · 2.4M',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Time
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    msg.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (msg.isOutgoing) ...[
            const SizedBox(width: 8),
            _Avatar(
              initials: 'DK',
              color: AppColors.primaryBlue,
              isGradient: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  final bool isGradient;

  const _Avatar({
    required this.initials,
    required this.color,
    this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isGradient
            ? const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.accentCyan],
              )
            : null,
        color: isGradient ? null : color,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final LinearGradient avatarColor;
  const _TypingBubble({required this.avatarColor});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.avatarColor,
            ),
            child: const Center(
              child: Text(
                'DK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Color(0x1AFFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final delay = i * 0.3;
                    final v = _ctrl.value;
                    final offset = ((v - delay) % 1.0 + 1.0) % 1.0;
                    final y = offset < 0.5
                        ? -4 * (offset / 0.5)
                        : -4 * (1 - (offset - 0.5) / 0.5);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabBtn({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.accentCyan : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.accentCyan : AppColors.textSecondary,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0x1AFFFFFF)),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

