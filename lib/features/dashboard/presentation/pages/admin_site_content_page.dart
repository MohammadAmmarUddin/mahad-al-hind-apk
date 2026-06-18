import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/home_section_toggles.dart';
import '../../../../core/widgets/upload_progress_dialog.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminSiteContentPage extends ConsumerStatefulWidget {
  const AdminSiteContentPage({super.key});
  @override
  ConsumerState<AdminSiteContentPage> createState() => _AdminSiteContentPageState();
}

class _AdminSiteContentPageState extends ConsumerState<AdminSiteContentPage> {
  Map<String, dynamic>? _content;
  bool _loading = true;
  List<Map<String, dynamic>> _heroImages = [];
  bool _slideshow = false;
  bool _imagesOnly = false;
  Map<String, bool> _sectionToggles = {};

  @override
  void initState() {
    super.initState();
    _fetchContent();
    _sectionToggles = HomeSectionToggles.getAll();
  }

  void _loadHeroConfig() {
    if (_content == null) return;
    final banners = _content!['heroBanners'] as List<dynamic>? ?? [];
    _heroImages = banners.map((b) {
      if (b is Map) {
        return {
          'url': b['url'] ?? '',
          'publicId': b['publicId'] ?? '',
        };
      }
      return {'url': '', 'publicId': ''};
    }).where((m) => (m['url'] as String).isNotEmpty).toList();
    final settings = _content!['heroBannerSettings'] as Map<String, dynamic>? ?? {};
    _slideshow = settings['slideshow'] == true;
    _imagesOnly = settings['imagesOnly'] == true;
  }

  Future<void> _saveHeroConfig() async {
    try {
      final banners = _heroImages.map((img) => {
        'url': img['url'],
        'publicId': img['publicId'] ?? '',
      }).toList();
      await ref.read(dioClientProvider).patch('/api/site-content/public', data: {
        'heroBanners': banners,
        'heroBannerSettings': {'slideshow': _slideshow, 'imagesOnly': _imagesOnly},
      });
    } catch (_) {}
  }

  Future<void> _fetchContent() async {
    try {
      final res = await ref.read(dioClientProvider).get('/api/site-content/public');
      final data = res.data;
      setState(() {
        if (data is Map && data['data'] is Map) _content = Map<String, dynamic>.from(data['data']);
        _loadHeroConfig();
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  void _toggleSection(String key, bool value) async {
    setState(() => _sectionToggles[key] = value);
    await HomeSectionToggles.setEnabled(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 800),
          content: Text('${HomeSectionToggles.sectionLabels[key]} ${value ? "enabled" : "disabled"}'),
          backgroundColor: value ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }

  void _addHeroImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await ref.read(fileUploadServiceProvider).pickImage(source: source);
      if (file == null || !mounted) return;

      UploadProgressDialog.show(
        context,
        file: file,
        folder: 'hero_banners',
        onSuccess: (url, publicId) {
          setState(() { _heroImages.add({'url': url, 'publicId': publicId}); });
          _saveHeroConfig();
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _removeHeroImage(int index) {
    final removed = _heroImages[index];
    setState(() { _heroImages.removeAt(index); });
    _saveHeroConfig();
    final publicId = removed['publicId'] as String? ?? '';
    if (publicId.isNotEmpty) {
      ref.read(dioClientProvider).delete('/api/cloudinary/destroy', data: {
        'publicId': publicId,
        'resourceType': 'image',
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site Content'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchContent),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTogglesCard(),
                const SizedBox(height: 20),
                _buildHeroBannerSection(),
                const SizedBox(height: 20),
                if (_content != null) ...[
                  const Text('Site Text Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField('Hero Title', _content!['home']?['heroTitle']?['en']),
                  _buildTextField('Hero Subtitle', _content!['home']?['heroSubtitle']?['en']),
                  _buildTextField('Hero Description', _content!['home']?['heroDescription']?['en']),
                  _buildTextField('Breaking News', _content!['breakingNews']?['message']?['en']),
                  _buildTextField('Enrollment Title', _content!['enrollmentWidget']?['title']?['en']),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionTogglesCard() {
    final sectionIcons = {
      'hero_banner': Icons.wallpaper,
      'news_feed': Icons.campaign,
      'stats': Icons.bar_chart,
      'featured_courses': Icons.school,
      'videos': Icons.play_circle_fill,
      'audio': Icons.headphones,
      'testimonials': Icons.rate_review,
      'gallery': Icons.photo_library,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.toggle_on, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Home Page Sections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_sectionToggles.values.where((v) => v).length}/${_sectionToggles.length} active',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Toggle sections visible on the home page', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ...HomeSectionToggles.sectionLabels.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final enabled = _sectionToggles[key] ?? true;
              final icon = sectionIcons[key] ?? Icons.circle;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: enabled ? AppColors.primarySurface.withOpacity(0.3) : AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: enabled ? AppColors.primary.withOpacity(0.15) : AppColors.textHint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: enabled ? AppColors.primary : AppColors.textHint, size: 18),
                  ),
                  title: Text(label, style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  )),
                  subtitle: Text(
                    enabled ? 'Visible on home page' : 'Hidden from home page',
                    style: TextStyle(fontSize: 11, color: enabled ? AppColors.success : AppColors.textHint),
                  ),
                  value: enabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _toggleSection(key, v),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBannerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wallpaper, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(child: Text('Hero Banner Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                FilledButton.icon(
                  onPressed: _heroImages.length >= 5 ? null : _addHeroImage,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Slide Show', style: TextStyle(fontSize: 14)),
              subtitle: Text(_slideshow ? 'Images rotate every 4 seconds' : 'Off - static first image only', style: const TextStyle(fontSize: 12)),
              value: _slideshow,
              activeColor: AppColors.primary,
              onChanged: (v) { setState(() => _slideshow = v); _saveHeroConfig(); },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Images Only', style: TextStyle(fontSize: 14)),
              subtitle: Text(_imagesOnly ? 'Show images without text overlay' : 'Show images with text overlay', style: const TextStyle(fontSize: 12)),
              value: _imagesOnly,
              activeColor: AppColors.primary,
              onChanged: (v) { setState(() => _imagesOnly = v); _saveHeroConfig(); },
            ),
            const SizedBox(height: 8),
            if (_heroImages.isEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    Text('No hero images yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Tap "Add" to upload banner images', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _heroImages.length,
                  itemBuilder: (ctx, i) {
                    return Stack(
                      children: [
                        Container(
                          width: 240,
                          margin: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _heroImages[i]['url'] ?? '',
                              fit: BoxFit.cover,
                              height: 160,
                              placeholder: (_, __) => Container(color: AppColors.surfaceVariant, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant, child: const Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, right: 16,
                          child: GestureDetector(
                            onTap: () => _removeHeroImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_heroImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${_heroImages.length}/5 images', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, dynamic value) {
    final ctrl = TextEditingController(text: value?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 6),
          TextField(controller: ctrl, maxLines: 2, decoration: const InputDecoration()),
        ],
      ),
    );
  }
}
