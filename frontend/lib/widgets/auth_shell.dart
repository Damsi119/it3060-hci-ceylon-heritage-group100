import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'heritage_app_bar.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.showBack = false,
    this.bottom,
  });

  final Widget child;
  final bool showBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeritageAppBar(showBack: showBack),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: child,
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
