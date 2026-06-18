import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminGalleryPage extends ConsumerStatefulWidget {
  const AdminGalleryPage({super.key});
  @override
  ConsumerState<AdminGalleryPage> createState() => _AdminGalleryPageState();
}

class _AdminGalleryPageState extends ConsumerState<AdminGalleryPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/gallery');
      final data = res.data;
      List<dynamic> items = [];
      if (data is Map && data['data'] is List) items = data['data'];
      if (data is List) items = data;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showUploadDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    File? selectedFile;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
                const Text('Upload to Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
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
                    if (source != null) {
                      final file = await ref.read(fileUploadServiceProvider).pickImage(source: source);
                      if (file != null) setSheetState(() => selectedFile = file);
                    }
                  },
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                    ),
                    child: selectedFile != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedFile!, fit: BoxFit.cover, width: double.infinity),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => selectedFile = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, size: 52, color: AppColors.primary.withOpacity(0.4)),
                              const SizedBox(height: 8),
                              const Text('Tap to select image', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Camera or Gallery', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title (optional)', prefixIcon: Icon(Icons.title, size: 20))),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description_outlined, size: 20))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: uploading ? null : () async {
                      if (selectedFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image'), backgroundColor: AppColors.error));
                        return;
                      }
                      setSheetState(() => uploading = true);
                      try {
                        final url = await ref.read(fileUploadServiceProvider).uploadImageToGallery(
                          selectedFile!,
                          title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : null,
                          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                        );
                        if (url != null) {
                          try {
                            await ref.read(dioClientProvider).post('/api/gallery', data: {
                              'imageUrl': url,
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'galleryType': 'general',
                            });
                          } catch (_) {}
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded successfully!'), backgroundColor: AppColors.success));
                            _fetchGallery();
                          }
                        } else {
                          setSheetState(() => uploading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Check connection.'), backgroundColor: AppColors.error));
                        }
                      } catch (e) {
                        setSheetState(() => uploading = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                      }
                    },
                    icon: uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload, size: 18),
                    label: Text(uploading ? 'Uploading...' : 'Upload'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(dynamic item) {
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final descCtrl = TextEditingController(text: item['description'] ?? '');
    String galleryType = item['galleryType'] ?? 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
                const Text('Edit Gallery Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item['imageUrl'] ?? item['url'] ?? '',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(height: 150, color: AppColors.surfaceVariant, child: const Icon(Icons.broken_image)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: galleryType,
                  items: ['general', 'student', 'faregin'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { if (v != null) setSheetState(() => galleryType = v); },
                  decoration: const InputDecoration(labelText: 'Gallery Type'),
                ),
                const SizedBox(height: 8),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title (optional)', prefixIcon: Icon(Icons.title, size: 20))),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description_outlined, size: 20))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ref.read(dioClientProvider).put('/api/gallery/${item['_id']}', data: {
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'galleryType': galleryType,
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!'), backgroundColor: AppColors.success));
                          _fetchGallery();
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                      }
                    },
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Remove from gallery? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(dioClientProvider).delete('/api/gallery/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: AppColors.success));
        _fetchGallery();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showDeleteOptions(String id) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              final item = _items.firstWhere((i) => i['_id'] == id, orElse: () => null);
              if (item != null) _showEditDialog(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Delete', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              _deleteItem(id);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Gallery'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchGallery),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_photo_alternate, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _fetchGallery, child: const Text('Retry')),
                ]))
              : _items.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text('No gallery items', style: TextStyle(color: AppColors.textSecondary)),
                    ]))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        final url = item['imageUrl'] ?? item['url'] ?? '';
                        final type = item['galleryType'] ?? '';
                        final id = item['_id'] ?? '';
                        return GestureDetector(
                          onTap: () => _showEditDialog(item),
                          onLongPress: () => _showDeleteOptions(id.toString()),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: url.toString().isNotEmpty
                                    ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                                        placeholder: (_, __) => Container(color: AppColors.surfaceVariant, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                        errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant, child: const Icon(Icons.broken_image)),
                                      )
                                    : Container(color: AppColors.surfaceVariant, child: const Icon(Icons.image)),
                              ),
                              if (type.toString().isNotEmpty)
                                Positioned(
                                  top: 4, left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                    child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 9)),
                                  ),
                                ),
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => _showDeleteOptions(id.toString()),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.more_vert, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
