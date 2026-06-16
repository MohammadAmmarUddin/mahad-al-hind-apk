import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/rating_bar.dart';

class ReviewCard extends StatelessWidget {
  final String name;
  final String comment;
  final double rating;
  final String? date;
  final String? avatarUrl;

  const ReviewCard({
    super.key,
    required this.name,
    required this.comment,
    required this.rating,
    this.date,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (date != null) Text(date!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingBar(rating: rating),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
