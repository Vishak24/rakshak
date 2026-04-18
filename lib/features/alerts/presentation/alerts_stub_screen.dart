import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rk_label.dart';

class AlertsStubScreen extends StatelessWidget {
  const AlertsStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: RkLabel(
          text: 'COMING SOON',
        ),
      ),
    );
  }
}
