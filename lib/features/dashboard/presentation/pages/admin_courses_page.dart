import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminCoursesPage extends ConsumerStatefulWidget {
  const AdminCoursesPage({super.key});
  @override
  ConsumerState<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends ConsumerState<AdminCoursesPage> {
  List<dynamic> _courses = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() { _loading = true; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/course/getAllCourses');
      final data = res.data;
      setState(() {
        _courses = (data is List) ? data : [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  void _showCourseDialog({dynamic course}) {
    final isEdit = course != null;
    final titleCtrl = TextEditingController(text: course?['title'] ?? '');
    final magnetCtrl = TextEditingController(text: course?['magnetLine'] ?? '');
    final detailsCtrl = TextEditingController(text: _stripHtml(course?['details'] ?? ''));
    final reqCtrl = TextEditingController(text: course?['requirements'] ?? '');
    final catCtrl = TextEditingController(text: course?['category'] ?? '');
    final priceCtrl = TextEditingController(text: course?['price']?.toString() ?? '');
    final discountCtrl = TextEditingController(text: course?['discount']?.toString() ?? '');
    final whatsappCtrl = TextEditingController(text: course?['whatsappGroupLink'] ?? '');
    String? bannerUrl = course?['banner'];
    String? syllabusUrl = course?['syllabus'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickAndUploadBanner(ImageSource source) async {
            final file = await ref.read(fileUploadServiceProvider).pickImage(source: source);
            if (file == null) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading banner...'), backgroundColor: AppColors.info));
            final result = await ref.read(fileUploadServiceProvider).uploadToCloudinary(file, folder: 'course_banners');
            if (result != null) {
              setDialogState(() => bannerUrl = result.url);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner uploaded!'), backgroundColor: AppColors.success));
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed'), backgroundColor: AppColors.error));
            }
          }

          Future<void> pickAndUploadSyllabus() async {
            final file = await ref.read(fileUploadServiceProvider).pickAny();
            if (file == null) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading syllabus...'), backgroundColor: AppColors.info));
            final result = await ref.read(fileUploadServiceProvider).uploadToCloudinary(file, folder: 'course_syllabus');
            if (result != null) {
              setDialogState(() => syllabusUrl = result.url);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syllabus uploaded!'), backgroundColor: AppColors.success));
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed'), backgroundColor: AppColors.error));
            }
          }

          return AlertDialog(
            title: Text(isEdit ? 'Edit Course' : 'Create Course'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', prefixIcon: Icon(Icons.title))),
                  const SizedBox(height: 8),
                  TextField(controller: magnetCtrl, decoration: const InputDecoration(labelText: 'Magnet Line', prefixIcon: Icon(Icons.bookmark_outline))),
                  const SizedBox(height: 8),
                  TextField(controller: detailsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Details', prefixIcon: Icon(Icons.description_outlined))),
                  const SizedBox(height: 8),
                  TextField(controller: reqCtrl, decoration: const InputDecoration(labelText: 'Requirements', prefixIcon: Icon(Icons.checklist))),
                  const SizedBox(height: 8),
                  TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount'))),
                  ]),
                  const SizedBox(height: 12),
                  const Align(alignment: Alignment.centerLeft, child: Text('Banner Image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final source = await showModalBottomSheet<ImageSource>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
                            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
                          ]),
                        ),
                      );
                      if (source != null) pickAndUploadBanner(source);
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: bannerUrl != null && bannerUrl!.isNotEmpty
                          ? Stack(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: bannerUrl!, fit: BoxFit.cover, width: double.infinity)),
                              Positioned(top: 4, right: 4, child: GestureDetector(
                                onTap: () => setDialogState(() => bannerUrl = null),
                                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                              )),
                            ])
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textHint),
                              const SizedBox(height: 6),
                              Text('Tap to upload banner', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(alignment: Alignment.centerLeft, child: Text('Syllabus PDF / Document', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: pickAndUploadSyllabus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: syllabusUrl != null && syllabusUrl!.isNotEmpty
                          ? Row(children: [
                              const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(syllabusUrl!.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                              GestureDetector(
                                onTap: () => setDialogState(() => syllabusUrl = null),
                                child: const Icon(Icons.close, size: 18, color: AppColors.textHint),
                              ),
                            ])
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.upload_file, size: 20, color: AppColors.textHint),
                              const SizedBox(width: 8),
                              Text('Tap to upload file', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: whatsappCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Group Link', prefixIcon: Icon(Icons.chat_outlined))),
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
                  Navigator.pop(ctx);
                  final payload = {
                    'title': titleCtrl.text.trim(),
                    'magnetLine': magnetCtrl.text.trim(),
                    'details': '<p>${detailsCtrl.text.trim()}</p>',
                    'requirements': reqCtrl.text.trim(),
                    'category': catCtrl.text.trim(),
                    'price': priceCtrl.text.trim(),
                    'discount': discountCtrl.text.trim(),
                    'syllabus': syllabusUrl ?? '',
                    'whatsappGroupLink': whatsappCtrl.text.trim(),
                    'banner': bannerUrl ?? '',
                  };
                  try {
                    if (isEdit) {
                      await ref.read(dioClientProvider).patch('/api/course/${course['_id']}', data: payload);
                    } else {
                      await ref.read(dioClientProvider).post('/api/course', data: payload);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Course updated' : 'Course created'), backgroundColor: AppColors.success),
                      );
                      _fetchCourses();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                icon: Icon(isEdit ? Icons.save : Icons.add, size: 16),
                label: Text(isEdit ? 'Update' : 'Create'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCourseDetail(dynamic course) {
    final title = course['title'] ?? '';
    final banner = course['banner'];
    final price = course['price']?.toString() ?? '0';
    final discount = course['discount']?.toString() ?? '0';
    final students = (course['students'] as List?)?.length ?? 0;
    final videos = (course['videos'] as List?)?.length ?? 0;
    final category = course['category'] ?? '';
    final details = _stripHtml(course['details'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
              if (banner != null && banner.toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                  child: CachedNetworkImage(imageUrl: banner, width: double.infinity, height: 180, fit: BoxFit.cover),
                )
              else
                Container(height: 120, width: double.infinity, decoration: const BoxDecoration(gradient: AppColors.primaryGradient), child: const Icon(Icons.school, color: Colors.white, size: 48)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
                        child: Text(category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _statChip(Icons.people, '$students students', AppColors.primary),
                      _statChip(Icons.play_circle, '$videos videos', AppColors.secondary),
                      _statChip(Icons.attach_money, '\u20B9$price', AppColors.accent),
                      if (discount != '0')
                        _statChip(Icons.local_offer, '$discount% OFF', AppColors.error),
                    ],
                  ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(details, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                    ],
                    if (course['requirements'] != null && (course['requirements'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(course['requirements'], style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showCourseDialog(course: course);
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              _deleteCourse(course['_id']);
                            },
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _deleteCourse(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(dioClientProvider).delete('/api/course/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted'), backgroundColor: AppColors.success));
        _fetchCourses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  String _stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _courses
        : _courses.where((c) => (c['title'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Courses'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCourses),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Course', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? const Center(child: Text('No courses found'))
                    : RefreshIndicator(
                        onRefresh: _fetchCourses,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final c = filtered[i];
                            final banner = c['banner'];
                            final price = c['price']?.toString() ?? '0';
                            final students = (c['students'] as List?)?.length ?? 0;
                            final videosCount = (c['videos'] as List?)?.length ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _showCourseDetail(c),
                                onLongPress: () => _showCourseDialog(course: c),
                                leading: banner != null && banner.toString().isNotEmpty
                                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: banner, width: 60, height: 45, fit: BoxFit.cover))
                                    : Container(width: 60, height: 45, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.school, color: Colors.white, size: 20)),
                                title: Text(c['title'] ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Row(children: [
                                  Text('\u20B9$price', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  Text(' \u2022 $students students \u2022 $videosCount videos', style: const TextStyle(fontSize: 11)),
                                ]),
                                trailing: PopupMenuButton(
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                                    const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_outlined, size: 16), SizedBox(width: 8), Text('Share')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'edit') _showCourseDialog(course: c);
                                    else if (val == 'share') Share.share('Check out ${c['title']} on Ma\'hadul Qiraat!');
                                    else if (val == 'delete') _deleteCourse(c['_id']);
                                  },
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
}
