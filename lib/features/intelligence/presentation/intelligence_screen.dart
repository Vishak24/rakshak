import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_card.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/settings_provider.dart';

class IntelligenceScreen extends ConsumerStatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  ConsumerState<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends ConsumerState<IntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcController;
  final List<ScanStep> _steps = [];
  double _arcProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _steps.addAll([
      ScanStep(
        icon: Icons.location_on_outlined,
        labelKey: {'en': 'Scanning location...', 'ta': 'இருப்பிடத்தை ஸ்கேன் செய்கிறது...'},
        doneAt: 1.2,
        arcTarget: 0.3,
      ),
      ScanStep(
        icon: Icons.history_outlined,
        labelKey: {'en': 'Analyzing history...', 'ta': 'வரலாற்றை பகுப்பாய்வு செய்கிறது...'},
        doneAt: 2.5,
        arcTarget: 0.65,
      ),
      ScanStep(
        icon: Icons.local_police_outlined,
        labelKey: {'en': 'Calculating ETA...', 'ta': 'ETA கணக்கிடுகிறது...'},
        doneAt: 4.0,
        arcTarget: 1.0,
      ),
    ]);

    _startScan();
  }

  Future<void> _startScan() async {
    _arcController.forward();

    for (final step in _steps) {
      await Future.delayed(Duration(milliseconds: (step.doneAt * 1000).toInt()));
      if (mounted) {
        setState(() {
          step.done = true;
          _arcProgress = step.arcTarget;
        });
      }
    }

    // Wait a bit then navigate to score screen
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.pushReplacement('/score');
    }
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Arc Progress
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: ArcProgressPainter(
                    progress: _arcProgress,
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.accent,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RkLabel.medium(
                          AppStrings.get({'en': 'ANALYZING', 'ta': 'பகுப்பாய்வு'}, lang),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${(_arcProgress * 100).toInt()}%',
                          style: AppText.display1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Scan Steps
              ..._steps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: RkCard(
                      child: Row(
                        children: [
                          Icon(
                            step.icon,
                            color: step.done ? AppColors.accent : AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              AppStrings.get(step.labelKey, lang),
                              style: AppText.bodyMedium,
                            ),
                          ),
                          if (step.done)
                            Text(
                              'OK',
                              style: AppText.labelLarge.copyWith(
                                color: AppColors.accent,
                              ),
                            )
                          else
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: AppSpacing.xl),

              // Info Cards Row
              Row(
                children: [
                  Expanded(
                    child: RkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RkLabel.medium('THREAT LEVEL'),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'NOMINAL',
                            style: AppText.h3.copyWith(
                              color: AppColors.accent,
                            ),
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
                          RkLabel.medium('ENCRYPTION'),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'AES-256',
                            style: AppText.h3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // System Integrity Card
              RkCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        RkLabel.medium('SYSTEM INTEGRITY'),
                        const Spacer(),
                        RkLabel.medium(
                          'PROCESSING...',
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LinearProgressIndicator(
                      value: _arcProgress,
                      color: AppColors.accent,
                      backgroundColor: AppColors.surfaceLight,
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

class ScanStep {
  final IconData icon;
  final Map<String, String> labelKey;
  final double doneAt;
  final double arcTarget;
  bool done;

  ScanStep({
    required this.icon,
    required this.labelKey,
    required this.doneAt,
    required this.arcTarget,
    this.done = false,
  });
}

class ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;

  ArcProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(ArcProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
