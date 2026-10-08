import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

class HeritageLogo extends StatelessWidget {
  const HeritageLogo({
    super.key,
    this.compact = false,
    this.showTagline = false,
  });

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.spa, size: compact ? 22 : 34, color: AppColors.gold),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              compact ? 'Ceylon Heritage' : 'CEYLON HERITAGE',
              style: GoogleFonts.playfairDisplay(
                fontSize: compact ? 14 : 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                height: 1,
              ),
            ),
            if (showTagline && !compact)
              const Text(
                'EXPLORE - DISCOVER - PRESERVE',
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
