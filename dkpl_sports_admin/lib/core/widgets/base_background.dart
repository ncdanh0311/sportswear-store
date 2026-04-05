import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BaseBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const BaseBackground({
    Key? key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient, // Áp dụng gradient xanh
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Để nhìn xuyên thấu xuống gradient
        appBar: appBar,
        body: SafeArea(child: child),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}