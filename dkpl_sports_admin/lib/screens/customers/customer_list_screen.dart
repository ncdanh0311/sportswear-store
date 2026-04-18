import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/user_model.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  Future<void> _setActive(UserModel user, bool nextActive) async {
    final canManage = RolePermissions.canManageCustomers(AuthService.instance.currentUser?.roleId);
    if (!canManage) return;

    final title = nextActive ? 'Mở khóa tài khoản' : 'Ban tài khoản';
    final content = nextActive
        ? 'Bạn muốn mở khóa tài khoản "${user.fullName}"?'
        : 'Bạn muốn Ban tài khoản "${user.fullName}"?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xac nhan')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set({
        'isActive': nextActive,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nextActive ? 'Đã mở khóa tài khoản' : 'Đã Ban tài khoản.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thao tác thất bại: $e')));
    }
  }

  UserModel _buildUser(QueryDocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    if ((map['id'] ?? '').toString().isEmpty) {
      map['id'] = doc.id;
    }
    return UserModel.fromMap(map);
  }

  @override
  Widget build(BuildContext context) {
    final canManage = RolePermissions.canManageCustomers(AuthService.instance.currentUser?.roleId);
    final usersRef = FirebaseFirestore.instance.collection('users');

    if (!canManage) {
      return BaseBackground(
        appBar: AppBar(
          title: const Text('Quản lý khách hàng', style: AppStyles.h2),
          backgroundColor: Colors.transparent,
        ),
        child: const Center(
          child: Text(
            'Bạn không có quyền quản lý khách hàng',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return BaseBackground(
      appBar: AppBar(
        title: const Text('Quản lý khách hàng', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Loi tai khach hang: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Chưa có khách hàng nào', style: TextStyle(color: Colors.white54)),
            );
          }

          docs.sort((a, b) {
            final aMap = a.data() as Map<String, dynamic>;
            final bMap = b.data() as Map<String, dynamic>;
            final aRaw = aMap['createdAt']?.toString() ?? '';
            final bRaw = bMap['createdAt']?.toString() ?? '';
            final aTime = DateTime.tryParse(aRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = DateTime.tryParse(bRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          final users = docs.map(_buildUser).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final isActive = user.isActive;
              final actionLabel = isActive ? 'Ban' : 'Mở khóa';
              final actionColor = isActive ? Colors.redAccent : Colors.greenAccent;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerDetailScreen(userId: user.id, initialUser: user),
                    ),
                  );
                },
                child: DKPLCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white12,
                        child: Icon(Icons.person_outline, color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName.isEmpty ? 'Chưa có tên' : user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: ${user.phone}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Member: ${user.membershipTier.isEmpty ? '---' : user.membershipTier}',
                              style: const TextStyle(color: AppColors.accentCyan, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Diem: ${user.rewardPoints}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isActive ? 'Trạng thái: Đang hoạt động' : 'Trạng thái: Bị khóa',
                              style: TextStyle(
                                color: isActive ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _setActive(user, !isActive),
                        style: TextButton.styleFrom(foregroundColor: actionColor),
                        child: Text(actionLabel),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
