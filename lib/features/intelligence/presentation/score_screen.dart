import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_card.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_status_chip.dart';
import '../../../core/providers/settings_provider.dart';

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).languageCode;
    const score = 78; // Stub high risk score
    final confidence = 0.87;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Critical Intelligence Chip
              Center(
                child: RkStatusChip(
                  label: '⚠ CRITICAL INTELLIGENCE',
                  color: AppColors.riskCritical,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Score with Diagonal Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Text(
                      score.toString(),
                      style: AppText.display1.copyWith(
                        fontSize: 96,
                        color: score > 75
                            ? AppColors.riskHigh
                            : score > 50
                                ? AppColors.riskMedium
                                : AppColors.riskLow,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: 20,
                    child: Transform.rotate(
                      angle: -0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HIGH RISK',
                          style: AppText.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Anomaly Text
              Text(
                lang == 'en'
                    ? 'Anomaly detected in your vicinity'
                    : 'உங்கள் சுற்றுப்புறத்தில் அசாதாரணம் கண்டறியப்பட்டது',
                style: AppText.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Alert Services Card
              RkCard(
                color: AppColors.surfaceLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'en'
                          ? 'Alert Emergency Services?'
                          : 'அவசர சேவைகளை எச்சரிக்கவா?',
                      style: AppText.h3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'அவசர சேவைகளை அழைக்கவா?',
                      style: AppText.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Yes Button
              RkButton(
                label: 'YES',
                onPressed: () => context.push('/sos'),
              ),

              const SizedBox(height: AppSpacing.sm),

              // No Button
              RkButton(
                label: 'NO',
                isSecondary: true,
                onPressed: () => context.pop(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // System Analysis Card
              RkCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RkLabel.medium('SYSTEM ANALYSIS'),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              RkLabel.medium(
                                'LIVE MONITORING',
                                color: AppColors.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'AI Sentinel has cross-referenced local incident reports with current biometric spikes. Confidence level: ${(confidence * 100).toInt()}%.',
                            style: AppText.bodyMedium,
                          ),
                        ],
                      ),
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
