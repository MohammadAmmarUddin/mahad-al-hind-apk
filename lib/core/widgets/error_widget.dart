import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    this.title,
    this.message,
    this.buttonText = 'Retry',
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 60,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Please try again later.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: buttonText!,
                onPressed: onRetry,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
