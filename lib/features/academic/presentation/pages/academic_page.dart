import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AcademicPage extends StatelessWidget {
  const AcademicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AcademicModule(
              title: 'Class Management',
              subtitle: 'Manage classes and schedules',
              icon: Icons.class_,
              color: AppColors.primary,
              isComingSoon: true,
            ),
            _AcademicModule(
              title: 'Batch Management',
              subtitle: 'Organize students into batches',
              icon: Icons.group,
              color: AppColors.secondary,
              isComingSoon: true,
            ),
            _AcademicModule(
              title: 'Subject Management',
              subtitle: 'Manage subjects and syllabus',
              icon: Icons.book,
              color: AppColors.accent,
              isComingSoon: true,
            ),
            _AcademicModule(
              title: 'Exam Management',
              subtitle: 'Create and manage examinations',
              icon: Icons.quiz,
              color: AppColors.info,
              isComingSoon: true,
            ),
            _AcademicModule(
              title: 'Results & Ranking',
              subtitle: 'View results and rankings',
              icon: Icons.leaderboard,
              color: AppColors.success,
              isComingSoon: true,
            ),
            _AcademicModule(
              title: 'Report Cards',
              subtitle: 'Generate and view report cards',
              icon: Icons.description,
              color: AppColors.warning,
              isComingSoon: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademicModule extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isComingSoon;

  const _AcademicModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isComingSoon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Coming Soon', style: TextStyle(fontSize: 10, color: AppColors.accent)),
                      ),
                    ],
                  ],
                ),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}
