import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/staff_model.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';

import 'add_staff_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  Future<bool> _deleteStaff(StaffModel staff) async {
    final currentUser = AuthService.instance.currentUser;
    final currentRole = currentUser?.role;

    final canDelete = RolePermissions.isManagerLike(currentRole);
    if (!canDelete) return false;

    if (currentUser?.id == staff.id) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong the xoa chinh tai khoan dang dang nhap.')),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoa nhan su'),
        content: Text('Ban co chac muon xoa "${staff.fullName}" khong?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoa')),
        ],
      ),
    );

    if (confirmed != true) return false;

    try {
      await FirebaseFirestore.instance.collection('staff').doc(staff.id).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': currentUser?.id ?? 'system',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da xoa tai khoan nhan su.')),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xoa that bai: $e')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManageStaff = RolePermissions.canManageStaff(AuthService.instance.currentUser?.role);
    final staffRef = FirebaseFirestore.instance.collection('staff');

    if (!canManageStaff) {
      return BaseBackground(
        appBar: AppBar(
          title: const Text('Quan ly nhan su', style: AppStyles.h2),
          backgroundColor: Colors.transparent,
        ),
        child: const Center(
          child: Text(
            'Ban khong co quyen quan ly nhan su.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return BaseBackground(
      appBar: AppBar(
        title: const Text('Quan ly nhan su', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: staffRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Loi tai nhan su: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          final docs = snapshot.data!.docs.where((doc) {
            final map = doc.data() as Map<String, dynamic>;
            return map['isDeleted'] != true;
          }).toList();

          docs.sort((a, b) {
            final aMap = a.data() as Map<String, dynamic>;
            final bMap = b.data() as Map<String, dynamic>;
            final aRaw = aMap['createdAt']?.toString() ?? '';
            final bRaw = bMap['createdAt']?.toString() ?? '';
            final aTime = DateTime.tryParse(aRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = DateTime.tryParse(bRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text('Chua co nhan vien nao.', style: TextStyle(color: Colors.white54)),
            );
          }

          final staffs = docs.map((doc) {
            final map = doc.data() as Map<String, dynamic>;
            return StaffModel.fromJson(map, doc.id);
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staffs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final staff = staffs[index];
              final currentUser = AuthService.instance.currentUser;
              final canDelete = RolePermissions.isManagerLike(currentUser?.role);
              final canDeleteThisStaff = canDelete && currentUser?.id != staff.id;

              if (!canDeleteThisStaff) {
                return _StaffItem(staff: staff);
              }

              return Dismissible(
                key: ValueKey('staff_${staff.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Xoa nhan su',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delete_outline, color: Colors.redAccent),
                    ],
                  ),
                ),
                confirmDismiss: (_) => _deleteStaff(staff),
                child: _StaffItem(staff: staff),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'btn_add_staff',
        backgroundColor: AppColors.accentCyan,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStaffScreen()));
        },
        child: const Icon(Icons.person_add_alt_1, color: AppColors.primaryNavy),
      ),
    );
  }
}

class _StaffItem extends StatelessWidget {
  const _StaffItem({required this.staff});

  final StaffModel staff;

  @override
  Widget build(BuildContext context) {
    return DKPLCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white12,
            backgroundImage: staff.avatar.isNotEmpty ? NetworkImage(staff.avatar) : null,
            child: staff.avatar.isEmpty ? const Icon(Icons.person_outline, color: Colors.white70) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.fullName.isEmpty ? 'Chua co ten' : staff.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(staff.email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text('Phone: ${staff.phone}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  'Role: ${RolePermissions.roleLabel(staff.role)}',
                  style: const TextStyle(color: AppColors.accentCyan, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${staff.id}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        ],
      ),
    );
  }
}
