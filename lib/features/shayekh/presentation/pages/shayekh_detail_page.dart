import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/shayekh_provider.dart';

class ShayekhDetailPage extends ConsumerWidget {
  final String shayekhId;
  const ShayekhDetailPage({super.key, required this.shayekhId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shayekhAsync = ref.watch(shayekhDetailProvider(shayekhId));

    return Scaffold(
      body: shayekhAsync.when(
        data: (shayekh) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(shayekh.name ?? '', style: const TextStyle(fontSize: 16)),
                background: shayekh.photo != null
                    ? CachedNetworkImage(imageUrl: shayekh.photo!, fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        child: const Center(
                          child: Icon(Icons.person, size: 80, color: Colors.white),
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shayekh.name ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(shayekh.country ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          child: const Text('Follow'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Courses', value: '${shayekh.totalCourses ?? 0}'),
                          _StatItem(label: 'Tilawah', value: '${shayekh.totalTilawah ?? 0}'),
                          _StatItem(label: 'Followers', value: '${shayekh.followers ?? 0}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      shayekh.bio ?? 'No bio available.',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    const Text('Specialization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        shayekh.specialization ?? 'N/A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
