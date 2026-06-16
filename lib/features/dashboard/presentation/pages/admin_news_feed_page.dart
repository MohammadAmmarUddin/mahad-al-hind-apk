import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/news_storage.dart';
import '../../../home/presentation/providers/news_feed_provider.dart';

class AdminNewsFeedPage extends ConsumerStatefulWidget {
  const AdminNewsFeedPage({super.key});
  @override
  ConsumerState<AdminNewsFeedPage> createState() => _AdminNewsFeedPageState();
}

class _AdminNewsFeedPageState extends ConsumerState<AdminNewsFeedPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = NewsStorage.getAll();
      _loading = false;
    });
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final courseIdCtrl = TextEditingController();
    String type = 'info';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.campaign, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Add Hot News'),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'News Title *',
                    hintText: 'e.g. New Hifz course starting!',
                    prefixIcon: Icon(Icons.title, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle (optional)',
                    hintText: 'Additional info',
                    prefixIcon: Icon(Icons.subtitles, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course ID (optional)',
                    hintText: 'Link to course detail',
                    prefixIcon: Icon(Icons.school, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category, size: 20),
                  ),
                  items: [
                    _typeItem('info', 'Info', AppColors.info),
                    _typeItem('urgent', 'Urgent', AppColors.error),
                    _typeItem('new', 'New', AppColors.success),
                    _typeItem('offer', 'Offer', AppColors.accent),
                    _typeItem('event', 'Event', const Color(0xFF7C3AED)),
                  ],
                  onChanged: (v) { if (v != null) setDialogState(() => type = v); },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                await NewsStorage.addItem({
                  'title': titleCtrl.text.trim(),
                  'subtitle': subtitleCtrl.text.trim().isNotEmpty ? subtitleCtrl.text.trim() : null,
                  'courseId': courseIdCtrl.text.trim().isNotEmpty ? courseIdCtrl.text.trim() : null,
                  'type': type,
                  'enabled': true,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadItems();
                  ref.invalidate(newsFeedProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('News item added'), backgroundColor: AppColors.success),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final subtitleCtrl = TextEditingController(text: item['subtitle'] ?? '');
    final courseIdCtrl = TextEditingController(text: item['courseId'] ?? '');
    String type = item['type'] ?? 'info';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Edit Hot News'),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'News Title *',
                    prefixIcon: Icon(Icons.title, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle',
                    prefixIcon: Icon(Icons.subtitles, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course ID',
                    prefixIcon: Icon(Icons.school, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category, size: 20),
                  ),
                  items: [
                    _typeItem('info', 'Info', AppColors.info),
                    _typeItem('urgent', 'Urgent', AppColors.error),
                    _typeItem('new', 'New', AppColors.success),
                    _typeItem('offer', 'Offer', AppColors.accent),
                    _typeItem('event', 'Event', const Color(0xFF7C3AED)),
                  ],
                  onChanged: (v) { if (v != null) setDialogState(() => type = v); },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                await NewsStorage.updateItem(item['_id'], {
                  'title': titleCtrl.text.trim(),
                  'subtitle': subtitleCtrl.text.trim().isNotEmpty ? subtitleCtrl.text.trim() : null,
                  'courseId': courseIdCtrl.text.trim().isNotEmpty ? courseIdCtrl.text.trim() : null,
                  'type': type,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadItems();
                  ref.invalidate(newsFeedProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('News item updated'), backgroundColor: AppColors.success),
                  );
                }
              },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEnabled(Map<String, dynamic> item) async {
    final newEnabled = !(item['enabled'] ?? true);
    await NewsStorage.updateItem(item['_id'], {'enabled': newEnabled});
    _loadItems();
    ref.invalidate(newsFeedProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newEnabled ? 'News enabled' : 'News disabled'),
          backgroundColor: newEnabled ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete News'),
        content: Text('Delete "${item['title']}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await NewsStorage.deleteItem(item['_id']);
              if (mounted) {
                Navigator.pop(ctx);
                _loadItems();
                ref.invalidate(newsFeedProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('News item deleted'), backgroundColor: AppColors.success),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _typeItem(String value, String label, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'urgent': return AppColors.error;
      case 'new': return AppColors.success;
      case 'offer': return AppColors.accent;
      case 'event': return const Color(0xFF7C3AED);
      default: return AppColors.info;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'urgent': return Icons.warning_amber;
      case 'new': return Icons.fiber_new;
      case 'offer': return Icons.local_offer;
      case 'event': return Icons.event;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hot News Feed'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add News', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      const Text('No news items yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Add news to show in the scrolling ticker', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add First News'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadItems(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      final enabled = item['enabled'] ?? true;
                      final type = item['type'] ?? 'info';
                      final typeColor = _typeColor(type);
                      final created = item['createdAt'] != null
                          ? DateTime.tryParse(item['createdAt'])
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Opacity(
                          opacity: enabled ? 1.0 : 0.5,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_typeIcon(type), color: typeColor, size: 20),
                            ),
                            title: Text(
                              item['title'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: enabled ? null : TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((item['subtitle'] ?? '').toString().isNotEmpty)
                                  Text(item['subtitle'], style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      created != null ? DateFormat('MMM d, yyyy').format(created) : '',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                                    ),
                                    if ((item['courseId'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.link, size: 10, color: AppColors.textHint),
                                      const Text(' Linked', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(children: [
                                    Icon(enabled ? Icons.visibility_off : Icons.visibility, size: 16, color: enabled ? AppColors.warning : AppColors.success),
                                    const SizedBox(width: 8),
                                    Text(enabled ? 'Disable' : 'Enable'),
                                  ]),
                                ),
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                              ],
                              onSelected: (val) {
                                if (val == 'toggle') _toggleEnabled(item);
                                else if (val == 'edit') _showEditDialog(item);
                                else if (val == 'delete') _deleteItem(item);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
