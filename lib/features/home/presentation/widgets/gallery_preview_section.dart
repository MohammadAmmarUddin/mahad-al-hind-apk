import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/section_header.dart';

class GalleryPreviewSection extends StatelessWidget {
  final List<dynamic> gallery;
  const GalleryPreviewSection({super.key, required this.gallery});

  @override
  Widget build(BuildContext context) {
    if (gallery.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Gallery',
          actionText: 'View All',
          onAction: () => context.push('/more/gallery'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: gallery.length > 8 ? 8 : gallery.length,
            itemBuilder: (context, index) {
              final item = gallery[index];
              final imageUrl = item['imageUrl'] ?? item['url'] ?? item['image'] ?? '';
              final id = item['_id'] ?? '';
              return GestureDetector(
                onTap: () => context.push('/more/gallery/$id'),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl.toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.primarySurface,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primarySurface,
                              child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 32),
                            ),
                          )
                        : Container(
                            color: AppColors.primarySurface,
                            child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 40),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
