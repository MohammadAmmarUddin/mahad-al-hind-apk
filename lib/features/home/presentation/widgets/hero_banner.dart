import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/hive_storage.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  List<String> get _heroImages {
    final data = HiveStorage.getCachedData('hero_banner_config');
    if (data is Map && data['images'] is List) {
      return (data['images'] as List).whereType<String>().where((u) => u.isNotEmpty).toList();
    }
    return [];
  }

  bool get _slideshowEnabled {
    final data = HiveStorage.getCachedData('hero_banner_config');
    if (data is Map) return data['slideshow'] == true;
    return false;
  }

  bool get _imagesOnly {
    final data = HiveStorage.getCachedData('hero_banner_config');
    if (data is Map) return data['imagesOnly'] == true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startSlideshow();
  }

  void _startSlideshow() {
    _timer?.cancel();
    if (_slideshowEnabled && _heroImages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % _heroImages.length;
        _pageController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _heroImages;
    final imagesOnly = _imagesOnly;

    if (images.isEmpty) {
      return _buildDefaultBanner(imagesOnly);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/courses'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 210,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (ctx, i) {
                    return CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        child: const Icon(Icons.broken_image, color: Colors.white, size: 40),
                      ),
                    );
                  },
                ),
                if (!imagesOnly) ...[
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
                          child: const Text('Assalamu Alaikum', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Ma'hadul Qira'at Al Hind",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Qira'at Academy \u2022 Est. 2022",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                if (images.length > 1)
                  Positioned(
                    bottom: imagesOnly ? 12 : 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        final active = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBanner(bool imagesOnly) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/courses'),
        child: Container(
          width: double.infinity,
          height: 210,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A3D1F), Color(0xFF0E5C28), Color(0xFF1B7A3D), Color(0xFF28A745)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              Positioned(top: -30, right: -20, child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
              Positioned(bottom: -20, left: -15, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
              if (!imagesOnly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.3))),
                        child: const Text('Assalamu Alaikum', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      const Text("Ma'hadul Qira'at\nAl Hind", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.15)),
                      const SizedBox(height: 4),
                      Text("Qira'at Academy \u2022 Est. 2022", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.3))),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explore Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
