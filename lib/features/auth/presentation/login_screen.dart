import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rk_button.dart';
import '../../../core/widgets/rk_label.dart';
import '../../../core/widgets/rk_pulse.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/settings_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty) return;

    setState(() => _isLoading = true);

    // Simulate login delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      context.go('/sentinel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // App Name
                Text(
                  'RAKSHAK',
                  style: AppText.display1.copyWith(
                    fontSize: 40,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Sentinel Active Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(width: 4),
                    RkLabel.small(
                      AppStrings.get(AppStrings.sentinel, lang),
                      color: AppColors.accent,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Phone Input
                Container(
                  decoration: BoxDecoration(
                    boxShadow: _phoneController.text.isNotEmpty
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: AppText.bodyLarge,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixText: '+91  ',
                      prefixStyle: AppText.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      hintText: '000 000 0000',
                      hintStyle: AppText.bodyLarge.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Security Notice
                Text(
                  'Access requires encrypted two-factor verification...',
                  style: AppText.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Login Button
                RkButton(
                  label: '${AppStrings.get(AppStrings.sendOtp, lang)} ›',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RkLabel.small('PRIVACY POLICY'),
                    const SizedBox(width: AppSpacing.xl),
                    RkLabel.small('SYSTEM TECHNICAL SUPPORT'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RkLabel.small(
                  'RAKSHAK SENTINEL V1.0',
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
