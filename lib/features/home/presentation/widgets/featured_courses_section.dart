import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/home_data.dart';

class FeaturedCoursesSection extends StatelessWidget {
  final HomeData homeData;
  const FeaturedCoursesSection({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    final courses = homeData.topCourses;
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Featured Courses',
          actionText: 'View All',
          onAction: () => context.push('/courses'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: courses.length > 5 ? 5 : courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseCard(course: course);
            },
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final dynamic course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final title = course['title'] ?? 'Course';
    final price = course['price'];
    final banner = course['banner'];
    final discount = course['discount'];
    final studentsCount = (course['students'] as List?)?.length ?? 0;
    final category = course['category'] ?? '';
    final courseId = course['_id'] ?? '';

    return GestureDetector(
      onTap: () => context.push('/course/$courseId'),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 115,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  if (banner != null && banner.toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: banner,
                        width: double.infinity,
                        height: 115,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                          child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                          child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        width: double.infinity,
                        height: 115,
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        child: const Center(child: Icon(Icons.school_rounded, color: Colors.white, size: 44)),
                      ),
                    ),
                  if (discount != null && discount.toString() != '0')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      title.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.people_rounded, color: AppColors.textSecondary, size: 12),
                        const SizedBox(width: 3),
                        Text('$studentsCount', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(
                          price == null || price == '0' || price == '' ? 'Free' : '\u20B9$price',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: (price == null || price == '0' || price == '') ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
