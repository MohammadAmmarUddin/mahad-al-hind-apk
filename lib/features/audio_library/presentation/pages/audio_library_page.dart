import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/auth_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/providers/core_providers.dart';
import '../providers/audio_provider.dart';
import '../widgets/audio_category_tabs.dart';
import '../widgets/audio_track_list.dart';
import '../widgets/mini_player.dart';

class AudioLibraryPage extends ConsumerWidget {
  const AudioLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0E5C28), AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Library',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Listen to Tilawah, Bayan & more',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    userAsync.when(
                      data: (user) {
                        if (user?.role == 'admin') {
                          return IconButton(
                            onPressed: () => _showUploadDialog(context, ref),
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                            tooltip: 'Upload Audio',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const AudioCategoryTabs(),
          const Expanded(
            child: AudioTrackList(),
          ),
          if (currentTrack != null) const MiniPlayer(),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    String category = 'Tilawah';
    File? selectedFile;
    String? uploadedUrl;
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
                const Text('Upload Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final file = await ref.read(fileUploadServiceProvider).pickAny();
                    if (file != null) {
                      setSheetState(() { selectedFile = file; uploading = true; });
                      try {
                        final result = await ref.read(fileUploadServiceProvider).uploadToCloudinary(file, folder: 'audio');
                        if (result != null) {
                          setSheetState(() { uploadedUrl = result.url; uploading = false; });
                        } else {
                          setSheetState(() { uploading = false; });
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Check connection.'), backgroundColor: AppColors.error));
                        }
                      } catch (e) {
                        setSheetState(() { uploading = false; });
                        if (context.mounted) {
                          final msg = e.toString().contains('Exception:')
                              ? e.toString().replaceFirst('Exception: ', '')
                              : 'Upload failed';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
                        }
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
                                Text(selectedFile?.path.split(Platform.pathSeparator).last ?? 'File uploaded',
                                    style: const TextStyle(fontSize: 13, color: AppColors.success)),
                              ])
                            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.audiotrack, size: 32, color: AppColors.textHint),
                                const SizedBox(height: 6),
                                Text('Tap to upload audio file', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title', prefixIcon: Icon(Icons.title, size: 20))),
                const SizedBox(height: 8),
                TextField(controller: artistCtrl, decoration: const InputDecoration(hintText: 'Artist / Shayekh', prefixIcon: Icon(Icons.person_outline, size: 20))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: ['Tilawah', 'Bayan', 'Azaan', 'Nasheed', 'Dars'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) { if (v != null) setSheetState(() => category = v); },
                  decoration: const InputDecoration(hintText: 'Category', prefixIcon: Icon(Icons.category_outlined, size: 20)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (uploading || uploadedUrl == null || titleCtrl.text.trim().isEmpty)
                        ? null
                        : () async {
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
                              ref.invalidate(filteredAudioProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio uploaded!'), backgroundColor: AppColors.success));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                              }
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
}
