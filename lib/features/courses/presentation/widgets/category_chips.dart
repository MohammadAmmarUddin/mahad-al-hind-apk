import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/courses_provider.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return coursesAsync.when(
      data: (courses) {
        final categories = courses
            .map((c) => c.category)
            .where((c) => c != null && c.isNotEmpty)
            .map((c) => c!)
            .toSet()
            .toList();
        if (categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = selectedCategory == null;
                return FilterChip(
                  label: const Text('All'),
                  selected: isSelected,
                  onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = null,
                  backgroundColor: AppColors.surfaceVariant,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }
              final cat = categories[index - 1];
              final isSelected = selectedCategory == cat;
              return FilterChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = isSelected ? null : cat,
                backgroundColor: AppColors.surfaceVariant,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
