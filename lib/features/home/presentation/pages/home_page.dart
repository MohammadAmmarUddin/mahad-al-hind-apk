import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/home_section_toggles.dart';
import '../providers/home_provider.dart';
import '../widgets/hero_banner.dart';
import '../widgets/stats_section.dart';
import '../widgets/featured_courses_section.dart';
import '../widgets/audio_preview_section.dart';
import '../widgets/videos_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/gallery_preview_section.dart';
import '../widgets/news_feed_marquee.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeDataAsync = ref.watch(homeDataProvider);
    final toggles = HomeSectionToggles.getAll();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(homeDataProvider),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.surface,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      AppAssets.logo,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mosque, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Ma'hadul Qiraat",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/more/notifications'),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/courses'),
                ),
              ],
            ),
            if (toggles['news_feed'] == true)
              const SliverToBoxAdapter(child: NewsFeedMarquee()),
            homeDataAsync.when(
              data: (homeData) => SliverList(
                delegate: SliverChildListDelegate([
                  if (toggles['hero_banner'] == true) ...[
                    const HeroBanner(),
                  ],
                  if (toggles['stats'] == true) ...[
                    StatsSection(homeData: homeData),
                    const SizedBox(height: 20),
                  ],
                  if (toggles['featured_courses'] == true) ...[
                    FeaturedCoursesSection(homeData: homeData),
                    const SizedBox(height: 20),
                  ],
                  if (toggles['videos'] == true) ...[
                    VideosSection(videos: homeData.videos),
                    const SizedBox(height: 20),
                  ],
                  if (toggles['gallery'] == true) ...[
                    GalleryPreviewSection(gallery: homeData.gallery),
                    const SizedBox(height: 20),
                  ],
                  if (toggles['audio'] == true) ...[
                    const AudioPreviewSection(),
                    const SizedBox(height: 20),
                  ],
                  if (toggles['testimonials'] == true) ...[
                    TestimonialsSection(reviews: homeData.reviews),
                    const SizedBox(height: 20),
                  ],
                ]),
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text('Failed to load home data', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(homeDataProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
