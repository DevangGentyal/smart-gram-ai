import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/localization/localized_text.dart';
import '../../core/typography.dart';
import 'home_controller.dart';

class RecentChatTile extends StatelessWidget {
  const RecentChatTile({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final ConversationSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedText(
                      context,
                      en: summary.titleEn,
                      mr: summary.titleMr,
                    ),
                    style: AppTypography.marathiHeadline(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    localizedText(
                      context,
                      en: 'Updated ${_timeAgo(summary.lastInteraction)}',
                      mr: '${_timeAgo(summary.lastInteraction)} पूर्वी अद्ययावत',
                    ),
                    style: AppTypography.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} d ago';
    }
  }
}


