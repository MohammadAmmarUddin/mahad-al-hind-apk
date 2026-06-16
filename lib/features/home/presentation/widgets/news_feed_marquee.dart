import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/news_feed_provider.dart';

class NewsFeedMarquee extends ConsumerStatefulWidget {
  const NewsFeedMarquee({super.key});

  @override
  ConsumerState<NewsFeedMarquee> createState() => _NewsFeedMarqueeState();
}

class _NewsFeedMarqueeState extends ConsumerState<NewsFeedMarquee>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;
  double _scrollPosition = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted || _isPaused) return false;
      if (!_scrollController.hasClients) return false;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return false;

      _scrollPosition += 1.2;
      if (_scrollPosition >= maxScroll + 200) {
        _scrollPosition = 0;
      }
      _scrollController.jumpTo(_scrollPosition);
      return true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsFeedProvider);

    return newsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildMarquee(items);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMarquee(List<NewsItem> items) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'HOT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPaused = true),
              onTapUp: (_) => setState(() => _isPaused = false),
              onTapCancel: () => setState(() => _isPaused = false),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length * 3,
                itemBuilder: (ctx, i) {
                  final item = items[i % items.length];
                  return GestureDetector(
                    onTap: () {
                      if (item.courseId != null) {
                        context.push('/courses/${item.courseId}');
                      } else {
                        context.push('/more/notifications');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/more/notifications'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
