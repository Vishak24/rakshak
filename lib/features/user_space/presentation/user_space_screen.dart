import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_card.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';
import '../../../core/widgets/rk_status_chip.dart';
import '../../../core/providers/settings_provider.dart';
import 'user_controller.dart';

class UserSpaceScreen extends ConsumerStatefulWidget {
  const UserSpaceScreen({super.key});

  @override
  ConsumerState<UserSpaceScreen> createState() => _UserSpaceScreenState();
}

class _UserSpaceScreenState extends ConsumerState<UserSpaceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userControllerProvider.notifier).loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).languageCode;
    final state = ref.watch(userControllerProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final user = state.profile;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No user data')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'USER SPACE',
                    style: AppText.h2,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '/ பயனர் பகுதி',
                    style: AppText.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Profile Card
              RkCard(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RkLabel.medium('USER SPACE / பயனர் பகுதி'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          user.name,
                          style: AppText.display2.copyWith(fontSize: 36),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          user.phone,
                          style: AppText.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            RkPulse(
                              color: AppColors.accent,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            RkLabel.small(
                              lang == 'en'
                                  ? 'SYSTEM ARMED / அமைப்பு செயல்படுகிறது'
                                  : 'அமைப்பு செயல்படுகிறது / SYSTEM ARMED',
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // QR Code Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.qr_code_scanner_outlined,
                                color: Color(0xFF00382E),
                                size: 32,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '127',
                                style: AppText.display1.copyWith(
                                  color: const Color(0xFF00382E),
                                ),
                              ),
                              RkLabel.small(
                                lang == 'en' ? 'SCANS PERFORMED' : 'ஸ்கேன்கள் செய்யப்பட்டன',
                                color: const Color(0xFF00382E),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.surfaceLight,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.accent,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Emergency Contacts Header
              Row(
                children: [
                  Text(
                    lang == 'en'
                        ? 'Emergency Contacts / அவசர தொடர்புகள்'
                        : 'அவசர தொடர்புகள் / Emergency Contacts',
                    style: AppText.h3,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      lang == 'en' ? 'Edit / திருத்து' : 'திருத்து / Edit',
                      style: AppText.labelMedium.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Emergency Contacts
              ...state.contacts.map((contact) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: RkCard(
                      child: Row(
                        children: [
                          Icon(
                            contact.relationship.toLowerCase().contains('mother')
                                ? Icons.female
                                : Icons.male,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: AppText.h4.copyWith(fontSize: 18),
                                ),
                                Text(
                                  contact.phone,
                                  style: AppText.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RkStatusChip(
                            label: contact.relationship.toLowerCase().contains('father')
                                ? 'PRIMARY'
                                : 'SECONDARY',
                            color: contact.relationship.toLowerCase().contains('father')
                                ? AppColors.riskLow
                                : AppColors.riskMedium,
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: AppSpacing.sm),

              // Police Contact Card
              RkCard(
                color: const Color(0xFF3D1F1F),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_police_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Police / காவல்துறை',
                            style: AppText.h3.copyWith(color: Colors.white),
                          ),
                          Text(
                            'Dial 100',
                            style: AppText.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RkStatusChip(
                      label: 'OFFICIAL / அதிகாரி',
                      color: AppColors.riskCritical,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // SOS Call Button
              RkButton(
                label: lang == 'en'
                    ? 'SOS Call / அவசர அழைப்பு'
                    : 'அவசர அழைப்பு / SOS Call',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
