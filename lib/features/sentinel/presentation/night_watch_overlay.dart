import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/settings_provider.dart';
import 'sentinel_controller.dart';

class NightWatchOverlay extends ConsumerWidget {
  const NightWatchOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).languageCode;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  RkPulse(
                    color: AppColors.accent,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  RkLabel.large(
                    'NIGHT WATCH ACTIVE',
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                AppStrings.get(AppStrings.nightWatch, lang),
                style: AppText.h2,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Description
              Text(
                lang == 'en'
                    ? 'Share your live location with emergency contacts for enhanced safety monitoring during night hours.'
                    : 'இரவு நேரங்களில் மேம்பட்ட பாதுகாப்பு கண்காணிப்புக்காக உங்கள் நேரடி இருப்பிடத்தை அவசர தொடர்புகளுடன் பகிரவும்.',
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Share Yes Button
              RkButton(
                label: lang == 'en'
                    ? 'Share Location'
                    : 'இருப்பிடத்தைப் பகிரவும்',
                onPressed: () {
                  ref.read(sentinelControllerProvider.notifier).toggleNightWatch();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Share No Button
              RkButton(
                label: lang == 'en' ? 'Not Now' : 'இப்போது இல்லை',
                isSecondary: true,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
