import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/typography.dart';

class UserChatBubble extends StatelessWidget {
  const UserChatBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: AppTypography.textTheme.bodyLarge,
        ),
      ),
    );
  }
}


