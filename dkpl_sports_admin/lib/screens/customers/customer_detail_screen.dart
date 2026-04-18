import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/user_model.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String userId;
  final UserModel? initialUser;

  const CustomerDetailScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Future<void> _setActive(UserModel user, bool nextActive) async {
    final canManage =
        RolePermissions.canManageCustomers(AuthService.instance.currentUser?.roleId);
    if (!canManage) return;

    final title = nextActive ? 'Mo khoa tai khoan' : 'Ban tai khoan';
    final content = nextActive
        ? 'Ban muon mo khoa tai khoan "${user.fullName}"?'
        : 'Ban muon ban tai khoan "${user.fullName}"?';

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
        SnackBar(
          content: Text(nextActive ? 'Da mo khoa tai khoan.' : 'Da ban tai khoan.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thao tac that bai: $e')),
      );
    }
  }

  UserModel? _fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data as Map<String, dynamic>);
    if ((map['id'] ?? '').toString().isEmpty) {
      map['id'] = doc.id;
    }
    return UserModel.fromMap(map);
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '---' : value,
              style: TextStyle(color: valueColor ?? Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        RolePermissions.canManageCustomers(AuthService.instance.currentUser?.roleId);

    return DefaultTabController(
      length: 3,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          final user = snapshot.hasData ? _fromDoc(snapshot.data!) : widget.initialUser;

          return BaseBackground(
            appBar: AppBar(
              title: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName : 'Thong tin khach hang',
                style: AppStyles.h2,
              ),
              backgroundColor: Colors.transparent,
              actions: [
                if (user != null && canManage)
                  IconButton(
                    icon: Icon(user.isActive ? Icons.lock_outline : Icons.lock_open_outlined),
                    onPressed: () => _setActive(user, !user.isActive),
                    tooltip: user.isActive ? 'Ban tai khoan' : 'Mo khoa tai khoan',
                  ),
              ],
              bottom: const TabBar(
                indicatorColor: AppColors.accentCyan,
                labelColor: AppColors.accentCyan,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Thong tin'),
                  Tab(text: 'Don hang'),
                  Tab(text: 'Member'),
                ],
              ),
            ),
            child: Builder(
              builder: (context) {
                if (user == null) {
                  return const Center(
                    child: Text('Khong tim thay thong tin khach hang.', style: TextStyle(color: Colors.white70)),
                  );
                }

                return TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DKPLCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thong tin co ban',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                _infoRow('ID', user.id, valueColor: Colors.white38),
                                _infoRow('Ho ten', user.fullName),
                                _infoRow('Email', user.email),
                                _infoRow('Phone', user.phone),
                                _infoRow('Gioi tinh', user.gender),
                                _infoRow('Ngay sinh', user.dob ?? ''),
                                _infoRow('Ngay tao', user.createdAt ?? ''),
                                _infoRow(
                                  'Trang thai',
                                  user.isActive ? 'Dang hoat dong' : 'Bi khoa',
                                  valueColor: user.isActive ? Colors.greenAccent : Colors.redAccent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Chua co backend lich su don hang. Se cap nhat sau.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DKPLCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thong tin Member',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            _infoRow('Cap bac', user.membershipTier),
                            _infoRow('Diem tich luy', user.rewardPoints.toString()),
                            const SizedBox(height: 8),
                            const Text(
                              'Lich su cap bac se duoc bo sung khi co backend.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
