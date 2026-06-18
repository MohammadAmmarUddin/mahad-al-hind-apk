import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/audio_track.dart';
import '../providers/audio_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/audio_section_tabs.dart';

class AudioLibraryPage extends ConsumerStatefulWidget {
  const AudioLibraryPage({super.key});

  @override
  ConsumerState<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends ConsumerState<AudioLibraryPage> {
  String _selectedSection = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ─── HEADER ───
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A3D1F), Color(0xFF1B7A3D)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audio Library', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Listen, learn, and grow', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 14),
                // Search bar
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search audio, reciters...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── SECTION TABS ───
          AudioSectionTabs(
            selected: _selectedSection,
            onSelected: (s) => setState(() => _selectedSection = s),
          ),

          // ─── CONTENT ───
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildSectionContent(),
          ),
        ],
      ),
      bottomSheet: const MiniPlayer(),
    );
  }

  Widget _buildSearchResults() {
    final results = ref.watch(audioSearchProvider(_searchQuery));
    return results.when(
      data: (tracks) {
        if (tracks.isEmpty) return const Center(child: Text('No results found', style: TextStyle(color: AppColors.textSecondary)));
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: tracks.length,
          itemBuilder: (ctx, i) => _buildTrackTile(tracks[i], tracks, i),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSectionContent() {
    if (_selectedSection == 'all') return _buildAllSections();
    return _buildCategorySection(_selectedSection);
  }

  Widget _buildAllSections() {
    final sections = ['tilawah', 'surah', 'juzz', 'maqamat'];
    final labels = {'tilawah': 'Tilawah', 'surah': 'Surah', 'juzz': 'Juzz', 'maqamat': 'Maqamat'};
    final icons = {'tilawah': Icons.menu_book, 'surah': Icons.book, 'juzz': Icons.auto_stories, 'maqamat': Icons.music_note};

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: sections.map((type) {
        final cats = ref.watch(audioCategoriesProvider(type));
        return cats.when(
          data: (categories) {
            if (categories.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(icons[type], size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(labels[type]!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _selectedSection = type),
                        child: const Text('See All', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) => _buildCategoryCard(categories[i]),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection(String type) {
    final cats = ref.watch(audioCategoriesProvider(type));
    return cats.when(
      data: (categories) {
        if (categories.isEmpty) return const Center(child: Text('No categories found'));
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: categories.length,
          itemBuilder: (ctx, i) => _buildCategoryListTile(categories[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCategoryCard(dynamic cat) {
    return GestureDetector(
      onTap: () => context.push('/audio/category/${cat.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withOpacity(0.9), AppColors.primary.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${cat.audioCount} tracks', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListTile(dynamic cat) {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.folder, color: Colors.white, size: 20),
      ),
      title: Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text('${cat.audioCount} tracks', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => context.push('/audio/category/${cat.id}'),
    );
  }

  Widget _buildTrackTile(AudioTrack track, List<AudioTrack> queue, int index) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isCurrent = currentTrack?.id == track.id;
    final isFav = ref.watch(favoritesProvider).contains(track.id);

    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isCurrent
            ? const Icon(Icons.equalizer, color: AppColors.primary, size: 22)
            : const Icon(Icons.play_arrow_rounded, color: AppColors.textSecondary, size: 22),
      ),
      title: Text(track.title, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: isCurrent ? AppColors.primary : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.reciter.isNotEmpty ? track.reciter : track.formattedDuration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 18, color: isFav ? AppColors.error : AppColors.textHint),
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(track.id),
          ),
        ],
      ),
      onTap: () {
        ref.read(currentTrackProvider.notifier).state = track;
        ref.read(audioQueueProvider.notifier).state = queue;
        final player = ref.read(audioPlayerServiceProvider);
        player.play(track.audioUrl);
        ref.read(isPlayingProvider.notifier).state = true;
        ref.read(audioRepositoryProvider).incrementPlayCount(track.id);
        context.push('/audio/player');
      },
    );
  }
}
