import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_card.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';
import '../../../core/widgets/rk_status_chip.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/settings_provider.dart';
import 'sentinel_controller.dart';
import 'night_watch_overlay.dart';

class SentinelScreen extends ConsumerStatefulWidget {
  const SentinelScreen({super.key});

  @override
  ConsumerState<SentinelScreen> createState() => _SentinelScreenState();
}

class _SentinelScreenState extends ConsumerState<SentinelScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timeTimer;
  String _currentTime = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Load risk score
    Future.microtask(() {
      ref.read(sentinelControllerProvider.notifier).loadRiskScore();
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSosButtonTap() {
    // Check if night watch should be shown
    final hour = DateTime.now().hour;
    final isNight = hour >= 20 || hour <= 5;

    if (isNight && !ref.read(sentinelControllerProvider).nightWatchActive) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const NightWatchOverlay(),
      );
    } else {
      context.push('/sos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).languageCode;
    final state = ref.watch(sentinelControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
            const SizedBox(width: 4),
            Text(
              'RAKSHAK',
              style: AppText.labelLarge.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        leadingWidth: 120,
        title: RkLabel.medium(
          'T. Nagar - Chennai',
          color: AppColors.textSecondary,
        ),
        centerTitle: true,
        actions: [
          Text(
            _currentTime,
            style: AppText.labelMedium,
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceLight,
            child: const Icon(
              Icons.person,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Text(
              lang == 'en' ? 'த' : 'A',
              style: AppText.labelLarge.copyWith(color: AppColors.accent),
            ),
            onPressed: () {
              ref.read(settingsProvider.notifier).toggleLanguage();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Risk Score Card
                  RkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RkStatusChip(
                          label: state.riskScore?.label ?? 'Unknown',
                          color: state.riskScore?.color ?? AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.riskScore?.score.toString() ?? '--',
                          style: AppText.display1.copyWith(
                            color: state.riskScore != null
                                ? (state.riskScore!.score > 75
                                    ? AppColors.riskHigh
                                    : state.riskScore!.score > 50
                                        ? AppColors.riskMedium
                                        : AppColors.riskLow)
                                : AppColors.textTertiary,
                          ),
                        ),
                        RkLabel.medium(
                          AppStrings.get(AppStrings.riskScore, lang),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        RkStatusChip(
                          label: state.riskScore != null
                              ? (state.riskScore!.score > 75
                                  ? 'CRITICAL'
                                  : state.riskScore!.score > 50
                                      ? 'ELEVATED'
                                      : 'PROTECTED')
                              : 'UNKNOWN',
                          color: state.riskScore != null
                              ? (state.riskScore!.score > 75
                                  ? AppColors.riskCritical
                                  : state.riskScore!.score > 50
                                      ? AppColors.riskMedium
                                      : AppColors.riskLow)
                              : AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // SOS Button
                  Center(
                    child: GestureDetector(
                      onTap: _handleSosButtonTap,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.03);
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SOS',
                                style: AppText.display1.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              RkLabel.medium(
                                'EMERGENCY',
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Intelligence Button
                  RkButton(
                    label: 'SAFETY INTELLIGENCE / பாதுகாப்பு குறியீடு',
                    isSecondary: true,
                    onPressed: () => context.push('/intelligence'),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: RkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RkLabel.medium(
                                AppStrings.get({'en': 'Incidents Today', 'ta': 'இன்றைய சம்பவங்கள்'}, lang),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '3',
                                style: AppText.h2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: RkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RkLabel.medium(
                                AppStrings.get({'en': 'Nearest Station', 'ta': 'அருகிலுள்ள நிலையம்'}, lang),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '2.3 km',
                                style: AppText.h2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // AI Monitoring Card
                  RkCard(
                    child: Row(
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
                        Expanded(
                          child: Text(
                            'Rakshak AI is monitoring local distress signals within 5km radius.',
                            style: AppText.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
