import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

final enrollmentStepProvider = StateProvider<int>((ref) => 0);

class EnrollmentPage extends ConsumerWidget {
  final String courseId;
  const EnrollmentPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(enrollmentStepProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enrollment')),
      body: Column(
        children: [
          // Stepper
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (i) {
                final isActive = i <= step;
                final isCurrent = i == step;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          // Content
          Expanded(
            child: step == 0
                ? _buildPlanSelection(ref)
                : step == 1
                    ? _buildPaymentMethod(context)
                    : _buildConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Enrollment Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'SSLCommerz Payment',
            subtitle: 'Pay online securely',
            icon: Icons.payment,
            isSelected: true,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Manual Enrollment',
            subtitle: 'Contact admin to enroll',
            icon: Icons.person_add,
            isSelected: false,
            onTap: () {},
          ),
          const Spacer(),
          AppButton(
            text: 'Continue',
            onPressed: () => ref.read(enrollmentStepProvider.notifier).state = 1,
            variant: ButtonVariant.gradient,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Secure payment powered by SSLCommerz', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const Spacer(),
          AppButton(
            text: 'Pay Now',
            onPressed: () {},
            variant: ButtonVariant.gradient,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, size: 60, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          const Text('Enrollment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('You have been enrolled successfully.'),
          const SizedBox(height: 32),
          AppButton(
            text: 'Start Learning',
            onPressed: () => context.go('/'),
            variant: ButtonVariant.primary,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
