import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/audio_provider.dart';

class AudioCategoryTabs extends ConsumerWidget {
  const AudioCategoryTabs({super.key});

  static const _categories = [
    {'name': 'All', 'value': null},
    {'name': 'Tilawah', 'value': 'Tilawah'},
    {'name': 'Azaan', 'value': 'Azaan'},
    {'name': 'Bayan', 'value': 'Bayan'},
    {'name': 'Nasheed', 'value': 'Nasheed'},
    {'name': 'Dars', 'value': 'Dars'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(audioCategoryProvider);

    return Container(
      height: 50,
      color: AppColors.primary,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = selected == cat['value'];
          return GestureDetector(
            onTap: () => ref.read(audioCategoryProvider.notifier).state =
                cat['value'] as String?,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat['name'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
