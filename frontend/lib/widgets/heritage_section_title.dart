import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

class HeritageSectionTitle extends StatelessWidget {
  const HeritageSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[badge!, const SizedBox(height: 10)],
        Text(
          title,
          style: GoogleFonts.notoSerif(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
