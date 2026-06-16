import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/section_header.dart';

class TestimonialsSection extends StatelessWidget {
  final List<dynamic> reviews;
  const TestimonialsSection({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'What Students Say'),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reviews.length > 5 ? 5 : reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _TestimonialCard(
                name: review['userName'] ?? review['name'] ?? 'Student',
                comment: review['comment'] ?? review['text'] ?? '',
                rating: (review['rating'] ?? 5).toDouble(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String comment;
  final double rating;

  const _TestimonialCard({required this.name, required this.comment, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primarySurface),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.format_quote_rounded, color: AppColors.primary.withOpacity(0.2), size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: const Color(0xFFD4AF37),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
