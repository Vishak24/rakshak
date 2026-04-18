import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Rakshak Scaffold with Bottom Navigation
/// Provides consistent layout with bottom nav bar
class RkScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;
  final String languageCode;

  const RkScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChanged,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTabChanged,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textTertiary,
          selectedLabelStyle: AppText.labelSmall,
          unselectedLabelStyle: AppText.labelSmall,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.shield_outlined),
              activeIcon: const Icon(Icons.shield),
              label: languageCode == 'ta' ? 'காவலன்' : 'Sentinel',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_outlined),
              activeIcon: const Icon(Icons.notifications),
              label: languageCode == 'ta' ? 'எச்சரிக்கைகள்' : 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: languageCode == 'ta' ? 'வரைபடம்' : 'Map',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: languageCode == 'ta' ? 'சுயவிவரம்' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
