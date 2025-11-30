import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiChatBubble extends StatelessWidget {
  const AiChatBubble({
    super.key,
    required this.text,
    required this.isPlaying,
    required this.onPlayPause,
  });

  final String text;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  Widget buildStyledText(String text) {
    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 15, height: 1.4),
        strong: const TextStyle(fontWeight: FontWeight.bold),
        listBullet: TextStyle(
          fontSize: 18,
          height: 1.4,
          color: Colors.black87,
        ),
        h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Play/Pause Button
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: InkWell(
                onTap: onPlayPause,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaying ? AppColors.primary : Colors.white,
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                    color: isPlaying ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),

            // Text
            Expanded(
              child: buildStyledText(text),
            ),
          ],
        ),
      ),
    );
  }
}
