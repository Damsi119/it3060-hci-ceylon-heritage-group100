import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

class HeritageLogo extends StatelessWidget {
  const HeritageLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 24 : 30,
          height: compact ? 24 : 30,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_florist_rounded,
            size: compact ? 16 : 19,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ceylon Heritage',
              style: GoogleFonts.domine(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                height: 1,
              ),
            ),
            if (!compact)
              const Text(
                'ACCOUNT MANAGEMENT',
                style: TextStyle(
                  fontSize: 7.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
