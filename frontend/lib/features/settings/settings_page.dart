import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/sizes.dart';
import '../../core/typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingsItem(title: 'Language', subtitle: 'Marathi / English'),
      _SettingsItem(title: 'Voice settings', subtitle: 'Female · Soft tone'),
      _SettingsItem(title: 'Clear history', subtitle: 'Remove saved prompts'),
      _SettingsItem(title: 'About', subtitle: 'Version 1.0.0'),
      _SettingsItem(title: 'Logout', subtitle: 'Sign out of account'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              onTap: () {
                // TODO: wire settings actions
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppTypography.textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: AppTypography.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsItem {
  _SettingsItem({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}


