import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminVideosPage extends ConsumerStatefulWidget {
  const AdminVideosPage({super.key});
  @override
  ConsumerState<AdminVideosPage> createState() => _AdminVideosPageState();
}

class _AdminVideosPageState extends ConsumerState<AdminVideosPage> {
  List<dynamic> _videos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/videos');
      final data = res.data;
      setState(() {
        _videos = (data is List) ? data : (data is Map && data['data'] is List ? data['data'] : []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String? _youtubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  String _normalizeYouTubeUrl(String url) {
    final id = _youtubeId(url);
    if (id != null) return 'https://www.youtube.com/embed/$id';
    return url;
  }

  void _showAddEditDialog({dynamic video}) {
    final isEdit = video != null;
    final titleCtrl = TextEditingController(text: video?['title'] ?? '');
    final tagCtrl = TextEditingController(text: video?['tag'] ?? '');
    final descCtrl = TextEditingController(text: video?['description'] ?? '');
    final urlCtrl = TextEditingController(text: video?['embedUrl'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Video' : 'Add Video'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: urlCtrl, decoration: const InputDecoration(hintText: 'YouTube URL', prefixIcon: Icon(Icons.link)), maxLines: 2),
              const SizedBox(height: 4),
              Text('Paste any YouTube URL (watch, share, shorts, embed)', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: tagCtrl, decoration: const InputDecoration(hintText: 'Tag (e.g. Tilawah)')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required'), backgroundColor: AppColors.error));
                return;
              }
              if (urlCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube URL is required'), backgroundColor: AppColors.error));
                return;
              }
              Navigator.pop(ctx);
              final payload = {
                'title': titleCtrl.text.trim(),
                'tag': tagCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'embedUrl': _normalizeYouTubeUrl(urlCtrl.text.trim()),
              };
              try {
                if (isEdit) {
                  await ref.read(dioClientProvider).patch('/api/videos/${video['_id']}', data: payload);
                } else {
                  await ref.read(dioClientProvider).post('/api/videos', data: payload);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Video updated' : 'Video added'), backgroundColor: AppColors.success));
                  _fetchVideos();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            },
            icon: Icon(isEdit ? Icons.save : Icons.add, size: 16),
            label: Text(isEdit ? 'Update' : 'Add'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo(dynamic video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Remove this video? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(dioClientProvider).delete('/api/videos/${video['_id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: AppColors.success));
        _fetchVideos();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Videos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchVideos),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _fetchVideos, child: const Text('Retry')),
                  ],
                ))
              : _videos.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.videocam_outlined, size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text('No videos found', style: TextStyle(color: AppColors.textSecondary)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetchVideos,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _videos.length,
                        itemBuilder: (ctx, i) {
                          final v = _videos[i];
                          final vid = _youtubeId(v['embedUrl']);
                          final thumb = vid != null ? 'https://img.youtube.com/vi/$vid/mqdefault.jpg' : null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: thumb != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: thumb, width: 80, height: 56, fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(width: 80, height: 56, color: AppColors.surfaceVariant, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                      errorWidget: (_, __, ___) => Container(width: 80, height: 56, color: AppColors.surfaceVariant, child: const Icon(Icons.play_circle)),
                                    ))
                                  : Container(width: 80, height: 56, color: AppColors.surfaceVariant, child: const Icon(Icons.play_circle, color: AppColors.primary)),
                              title: Text(v['title'] ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(v['tag'] ?? '', style: const TextStyle(fontSize: 12)),
                              trailing: PopupMenuButton(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                                ],
                                onSelected: (val) {
                                  if (val == 'edit') _showAddEditDialog(video: v);
                                  else if (val == 'delete') _deleteVideo(v);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
