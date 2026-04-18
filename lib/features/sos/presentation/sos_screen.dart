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
import '../../../core/providers/settings_provider.dart';
import 'sos_controller.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  bool _isPhase2 = false;
  Timer? _timeTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    
    // Trigger SOS and auto-advance to phase 2
    Future.delayed(const Duration(milliseconds: 100), () {
      ref.read(sosControllerProvider.notifier).triggerSos();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isPhase2 = true);
      }
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).languageCode;

    return PopScope(
      canPop: _isPhase2,
      child: Scaffold(
        backgroundColor: _isPhase2 ? AppColors.background : const Color(0xFFFF3B55),
        body: SafeArea(
          child: _isPhase2 ? _buildPhase2(lang) : _buildPhase1(lang),
        ),
      ),
    );
  }

  Widget _buildPhase1(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: 0.785398, // 45 degrees in radians
              child: const Icon(
                Icons.add,
                size: 96,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              lang == 'en' ? 'Contacting Emergency Services...' : 'அவசர சேவைகளை தொடர்பு கொள்கிறது...',
              style: AppText.h2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'RAKSHAK SENTINEL ACTIVE',
              style: AppText.labelMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase2(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Status Card
          RkCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(
                        Icons.shield,
                        color: AppColors.accent,
                        size: 32,
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.accent,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RkLabel.large(
                        'STATUS: SECURED',
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        lang == 'en' ? 'Help is on the way' : 'உதவி வந்து கொண்டிருக்கிறது',
                        style: AppText.h3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Instructions
          Text(
            'Your location is secured. Help is on the way. Please stay in a well-lit place.',
            style: AppText.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'உங்கள் இருப்பிடம் பாதுகாப்பானது. உதவி வந்து கொண்டிருக்கிறது. வெளிச்சமான இடத்தில் இருக்கவும்.',
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Patrol Active
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
                RkLabel.medium(
                  lang == 'en' ? 'Patrol Active' : 'ரோந்து செயலில்',
                  color: AppColors.accent,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Dismiss Button
          RkButton(
            label: lang == 'en' ? 'Dismiss Alert' : 'எச்சரிக்கையை நிராகரி',
            isSecondary: true,
            onPressed: () => context.go('/sentinel'),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info Row
          Row(
            children: [
              Expanded(
                child: RkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RkLabel.medium('CURRENT TIME'),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _currentTime,
                        style: AppText.h3,
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
                      RkLabel.medium('SIGNAL STRENGTH'),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: List.generate(
                          4,
                          (index) => const Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.signal_cellular_alt,
                              color: AppColors.accent,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
