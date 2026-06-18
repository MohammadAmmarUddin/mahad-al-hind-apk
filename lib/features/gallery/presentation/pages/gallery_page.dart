import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../core/localization/app_localizations.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});
  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    setState(() { _loading = true; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/gallery');
      final data = res.data;
      List<dynamic> items = [];
      if (data is Map && data['data'] is List) items = data['data'];
      if (data is List) items = data;
      setState(() { _items = items; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filtered = _filter == 'all'
        ? _items
        : _items.where((item) => (item['galleryType'] ?? '') == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('gallery'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(t.translate('noGalleryItems'), style: const TextStyle(color: AppColors.textSecondary)),
                ]))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('all', t.translate('allCourses')),
                            _filterChip('student', t.translate('studentGallery')),
                            _filterChip('general', t.translate('gallery')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchGallery,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final item = filtered[i];
                            final url = item['imageUrl'] ?? item['url'] ?? '';
                            final title = item['title'] ?? '';
                            return GestureDetector(
                              onTap: () => context.push('/more/gallery/$i', extra: item),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    url.toString().isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: url,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(color: AppColors.surfaceVariant, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                            errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant, child: const Icon(Icons.broken_image)),
                                          )
                                        : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image, size: 48)),
                                    if (title.isNotEmpty)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
                                          ),
                                          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterChip(String value, String label) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : AppColors.textPrimary)),
        selected: active,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceVariant,
        onSelected: (_) => setState(() => _filter = value),
        checkmarkColor: Colors.white,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
