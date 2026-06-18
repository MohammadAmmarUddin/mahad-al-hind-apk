import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';

class GalleryDetailPage extends StatelessWidget {
  final String galleryId;
  final Map<String, dynamic>? item;
  const GalleryDetailPage({super.key, required this.galleryId, this.item});

  @override
  Widget build(BuildContext context) {
    final url = item?['imageUrl'] ?? item?['url'] ?? '';
    final title = item?['title'] ?? '';
    final description = item?['description'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isNotEmpty ? title : 'Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share('Check this photo from Ma\'hadul Qiraat Al Hind'),
          ),
        ],
      ),
      body: url.toString().isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Icon(Icons.image, color: Colors.white, size: 80)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      placeholder: (_, __) => Container(
                        height: 300,
                        color: AppColors.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 300,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                  if (title.isNotEmpty || description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
