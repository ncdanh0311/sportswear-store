import 'package:flutter/material.dart';

import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/screens/auth/login_screen.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';

enum _AccountMenuAction { logout }

class AccountAppBarAction extends StatelessWidget {
  const AccountAppBarAction({super.key});

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'NV';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final name = user.fullName.isNotEmpty ? user.fullName : user.email;
    final roleLabel = RolePermissions.roleLabel(user.roleId);
    final initials = _initials(name);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<_AccountMenuAction>(
        tooltip: 'Tài khoản',
        onSelected: (action) async {
          if (action == _AccountMenuAction.logout) {
            await AuthService.instance.logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<_AccountMenuAction>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(roleLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<_AccountMenuAction>(
            value: _AccountMenuAction.logout,
            child: Text('Đăng xuất'),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accentCyan,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  Text(
                    roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}
