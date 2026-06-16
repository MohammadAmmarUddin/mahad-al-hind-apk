import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/feature_management/presentation/providers/feature_provider.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
          final featureFlags = ref.watch(featureFlagsProvider);

          return NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withOpacity(0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 64,
            elevation: 8,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school, color: AppColors.primary),
                label: 'Courses',
              ),
              NavigationDestination(
                icon: const Icon(Icons.headphones_outlined),
                selectedIcon: const Icon(Icons.headphones, color: AppColors.primary),
                label: 'Audio',
                enabled: featureFlags.isEnabled('audioLibrary'),
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_outlined),
                selectedIcon: Icon(Icons.menu, color: AppColors.primary),
                label: 'More',
              ),
            ],
          );
        },
      ),
    );
  }
}
