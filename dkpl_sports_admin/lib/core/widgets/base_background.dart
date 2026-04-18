import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'account_appbar_action.dart';

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
    PreferredSizeWidget? resolvedAppBar = appBar;
    if (appBar is AppBar) {
      final bar = appBar as AppBar;
      resolvedAppBar = AppBar(
        key: bar.key,
        title: bar.title,
        leading: bar.leading,
        automaticallyImplyLeading: bar.automaticallyImplyLeading,
        actions: [
          ...?bar.actions,
          const AccountAppBarAction(),
        ],
        backgroundColor: bar.backgroundColor,
        foregroundColor: bar.foregroundColor ?? Colors.white,
        elevation: bar.elevation,
        centerTitle: bar.centerTitle,
        titleSpacing: bar.titleSpacing,
        toolbarHeight: bar.toolbarHeight,
        toolbarOpacity: bar.toolbarOpacity,
        bottomOpacity: bar.bottomOpacity,
        bottom: bar.bottom,
        flexibleSpace: bar.flexibleSpace,
        iconTheme: bar.iconTheme,
        actionsIconTheme: bar.actionsIconTheme,
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient, // Áp dụng gradient xanh
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Để nhìn xuyên thấu xuống gradient
        appBar: resolvedAppBar,
        body: SafeArea(child: child),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
