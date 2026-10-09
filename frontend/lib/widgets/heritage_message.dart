import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

void showHeritageMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.danger : AppColors.greenDark,
        content: Text(message),
      ),
    );
}
