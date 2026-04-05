import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DKPLCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DKPLCard({Key? key, required this.child, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(
          0.05,
        ), // Hiệu ứng kính mờ (Glassmorphism)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
