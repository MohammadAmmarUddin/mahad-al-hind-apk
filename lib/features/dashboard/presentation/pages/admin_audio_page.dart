import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminAudioPage extends ConsumerStatefulWidget {
  const AdminAudioPage({super.key});
  @override
  ConsumerState<AdminAudioPage> createState() => _AdminAudioPageState();
}

class _AdminAudioPageState extends ConsumerState<AdminAudioPage> {
  List<dynamic> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAudio();
  }

  Future<void> _fetchAudio() async {
    setState(() { _loading = true; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/gallery');
      final data = res.data;
      List<dynamic> items = [];
      if (data is Map && data['data'] is List) items = data['data'];
      if (data is List) items = data;
      final audioItems = items.where((e) => e['type'] == 'audio' || e['galleryType'] == 'audio').toList();
      setState(() { _tracks = audioItems; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    String category = 'Tilawah';
    File? selectedFile;
    String? uploadedUrl;
    bool uploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Audio Track'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final file = await ref.read(fileUploadServiceProvider).pickAny();
                    if (file != null) {
                      setDialogState(() { selectedFile = file; uploading = true; });
                      final result = await ref.read(fileUploadServiceProvider).uploadToCloudinary(file, folder: 'audio');
                      if (result != null) {
                        setDialogState(() { uploadedUrl = result.url; uploading = false; });
                      } else {
                        setDialogState(() { uploading = false; });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed'), backgroundColor: AppColors.error));
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: uploading
                        ? Column(children: [
                            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                            const SizedBox(height: 8),
                            Text('Uploading...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ])
                        : uploadedUrl != null
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.audiotrack, color: AppColors.success, size: 20),
                                const SizedBox(width: 8),
                                Text(selectedFile?.path.split('/').last ?? 'File uploaded', style: const TextStyle(fontSize: 13, color: AppColors.success)),
                              ])
                            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.audiotrack, size: 32, color: AppColors.textHint),
                                const SizedBox(height: 6),
                                Text('Tap to upload audio file', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: artistCtrl, decoration: const InputDecoration(hintText: 'Artist / Shayekh')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ['Tilawah', 'Bayan', 'Azaan', 'Nasheed', 'Dars'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => category = v); },
                  decoration: const InputDecoration(hintText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploading || uploadedUrl == null ? null : () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(dioClientProvider).post('/api/gallery', data: {
                    'title': titleCtrl.text.trim(),
                    'artist': artistCtrl.text.trim(),
                    'category': category,
                    'imageUrl': uploadedUrl,
                    'type': 'audio',
                    'galleryType': 'audio',
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio added!'), backgroundColor: AppColors.success));
                    _fetchAudio();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTrack(dynamic track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Audio'),
        content: const Text('Remove this audio track?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = track['_id'];
    if (id == null) return;
    try {
      await ref.read(dioClientProvider).delete('/api/gallery/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: AppColors.success));
        _fetchAudio();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Audio'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAudio),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.audiotrack, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tracks.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.headphones_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No audio tracks', style: TextStyle(color: AppColors.textSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tracks.length,
                  itemBuilder: (ctx, i) {
                    final t = _tracks[i];
                    final thumb = t['imageUrl'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: thumb != null && thumb.toString().isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: thumb, width: 44, height: 44, fit: BoxFit.cover))
                            : Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.audiotrack, color: AppColors.primary),
                              ),
                        title: Text(t['title'] ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${t['artist'] ?? ''} • ${t['category'] ?? ''}', style: const TextStyle(fontSize: 12)),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                          ],
                          onSelected: (_) => _deleteTrack(t),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
