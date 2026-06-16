import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/home_data.dart';

class StatsSection extends ConsumerWidget {
  final HomeData homeData;
  const StatsSection({super.key, required this.homeData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseCount = homeData.topCourses.length;
    final videoCount = homeData.videos.length;
    final galleryCount = homeData.gallery.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatItem(count: '$courseCount', label: 'Courses', icon: Icons.school_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          _StatItem(count: '$videoCount', label: 'Videos', icon: Icons.play_circle_filled_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          _StatItem(count: '$galleryCount', label: 'Gallery', icon: Icons.photo_library_rounded, color: AppColors.secondary),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
