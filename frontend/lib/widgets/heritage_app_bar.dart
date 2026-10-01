import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'heritage_logo.dart';

class HeritageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HeritageAppBar({
    super.key,
    this.showBack = false,
    this.actions,
    this.backgroundColor = AppColors.background,
  });

  final bool showBack;
  final List<Widget>? actions;
  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      leading: showBack
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 21),
            )
          : null,
      automaticallyImplyLeading: false,
      title: const HeritageLogo(compact: true),
      actions: actions,
    );
  }
}
