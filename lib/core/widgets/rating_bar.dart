import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final int starCount;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRating;

  const RatingBar({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.starSize = 16,
    this.activeColor = AppColors.accent,
    this.inactiveColor = AppColors.surfaceVariant,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(starCount, (index) {
          final starValue = index + 1;
          if (starValue <= rating) {
            return Icon(Icons.star, size: starSize, color: activeColor);
          } else if (starValue - 0.5 <= rating) {
            return Icon(Icons.star_half, size: starSize, color: activeColor);
          }
          return Icon(Icons.star_border, size: starSize, color: inactiveColor);
        }),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: starSize * 0.8,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
