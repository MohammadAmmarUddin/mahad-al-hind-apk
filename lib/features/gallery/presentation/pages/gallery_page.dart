import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 20,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _GalleryTile(
                    index: index,
                    onTap: () => context.push('/more/gallery/$index'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const _GalleryTile({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.primaryLight];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors[index % 4], colors[(index + 1) % 4]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Icon(Icons.image, color: Colors.white.withOpacity(0.5), size: 48),
        ),
      ),
    );
  }
}
