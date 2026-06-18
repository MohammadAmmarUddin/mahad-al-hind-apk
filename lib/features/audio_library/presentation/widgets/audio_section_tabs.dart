import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AudioSectionTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const AudioSectionTabs({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _Tab('all', 'All'),
      _Tab('tilawah', 'Tilawah'),
      _Tab('surah', 'Surah'),
      _Tab('juzz', 'Juzz'),
      _Tab('maqamat', 'Maqamat'),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        itemBuilder: (ctx, i) {
          final tab = sections[i];
          final isActive = selected == tab.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(tab.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textPrimary)),
              selected: isActive,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              onSelected: (_) => onSelected(tab.key),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    );
  }
}

class _Tab {
  final String key;
  final String label;
  const _Tab(this.key, this.label);
}
