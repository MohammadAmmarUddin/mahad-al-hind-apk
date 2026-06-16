import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double? iconSize;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 80,
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
              width: iconSize! * 1.5,
              height: iconSize! * 1.5,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: iconSize,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
