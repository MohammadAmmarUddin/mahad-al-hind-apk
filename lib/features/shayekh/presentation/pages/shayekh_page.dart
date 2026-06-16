import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/shayekh_provider.dart';

class ShayekhPage extends ConsumerWidget {
  const ShayekhPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shayekhAsync = ref.watch(shayekhListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Our Shayekh')),
      body: shayekhAsync.when(
        data: (shayekhList) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12,
          ),
          itemCount: shayekhList.length,
          itemBuilder: (context, index) {
            final shayekh = shayekhList[index];
            return GestureDetector(
              onTap: () => context.push('/more/shayekh/${shayekh.id}'),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: shayekh.photo != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: CachedNetworkImage(imageUrl: shayekh.photo!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(
                                  (shayekh.name ?? '')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            shayekh.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shayekh.specialization ?? '',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
