import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/localization/localized_text.dart';
import '../../core/sizes.dart';
import '../../core/typography.dart';
import 'home_controller.dart';
import 'recent_chat_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXL,
            vertical: AppSizes.paddingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedText(
                            context,
                            en: 'Hello ${state.userName}',
                            mr: 'नमस्कार ${state.userName}',
                          ),
                          style: AppTypography.marathiHeadline(fontSize: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          localizedText(
                            context,
                            en: 'Need help? Just ask.',
                            mr: 'मदत हवी आहे? विचार करा.',
                          ),
                          style: AppTypography.marathiHeadline(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/settings'),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.surface,
                      child: Icon(Icons.person_outline, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                localizedText(
                  context,
                  en: 'Recent conversations',
                  mr: 'मागील संभाषणे',
                ),
                style: AppTypography.marathiHeadline(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: state.recentConversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final summary = state.recentConversations[index];
                    return RecentChatTile(
                      summary: summary,
                      onTap: () => context.go('/chat/${summary.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1 + (_pulseController.value * 0.05);
                        return Transform.scale(
                          scale: scale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 30 * _pulseController.value + 10,
                                  spreadRadius: 6 * _pulseController.value,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                        child: InkWell(
                          onTap: () => context.go('/chat/new'),
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizedText(
                        context,
                        en: 'Ask the AI',
                        mr: 'AI ला विचारा',
                      ),
                      style: AppTypography.marathiHeadline(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


