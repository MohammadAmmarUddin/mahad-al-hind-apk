import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, text, gradient }
enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      ButtonSize.small => 36.0,
      ButtonSize.medium => 48.0,
      ButtonSize.large => 56.0,
    };

    final fontSize = switch (size) {
      ButtonSize.small => 12.0,
      ButtonSize.medium => 16.0,
      ButtonSize.large => 18.0,
    };

    final padding = switch (size) {
      ButtonSize.small => const EdgeInsets.symmetric(horizontal: 16),
      ButtonSize.medium => const EdgeInsets.symmetric(horizontal: 24),
      ButtonSize.large => const EdgeInsets.symmetric(horizontal: 32),
    };

    if (variant == ButtonVariant.gradient) {
      return Container(
        width: isFullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildContent(fontSize),
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: switch (variant) {
        ButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.primary,
            foregroundColor: textColor ?? Colors.white,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _buildContent(fontSize),
        ),
        ButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.primarySurface,
            foregroundColor: textColor ?? AppColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _buildContent(fontSize),
        ),
        ButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            side: BorderSide(color: color ?? AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildContent(fontSize),
        ),
        ButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildContent(fontSize),
        ),
        _ => const SizedBox(),
      },
    );
  }

  Widget _buildContent(double fontSize) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor ?? Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600));
  }
}
