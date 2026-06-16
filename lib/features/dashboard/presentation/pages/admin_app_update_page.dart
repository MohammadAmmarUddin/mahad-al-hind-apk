import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_update_config.dart';
import '../../../../core/services/update_provider.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminAppUpdatePage extends ConsumerStatefulWidget {
  const AdminAppUpdatePage({super.key});
  @override
  ConsumerState<AdminAppUpdatePage> createState() => _AdminAppUpdatePageState();
}

class _AdminAppUpdatePageState extends ConsumerState<AdminAppUpdatePage> {
  final _versionCtrl = TextEditingController();
  final _minVersionCtrl = TextEditingController();
  final _apkUrlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _forceUpdate = false;
  bool _updateEnabled = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(adminUpdateConfigProvider).whenData((config) {
      if (config != null && mounted) {
        _versionCtrl.text = config.latestVersion;
        _minVersionCtrl.text = config.minVersion;
        _apkUrlCtrl.text = config.apkUrl;
        _notesCtrl.text = config.releaseNotes;
        setState(() {
          _forceUpdate = config.forceUpdate;
          _updateEnabled = config.updateEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _versionCtrl.dispose();
    _minVersionCtrl.dispose();
    _apkUrlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_versionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version is required'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_apkUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('APK URL is required'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(dioClientProvider).patch(
        '/api/admin/app-update',
        data: {
          'latestVersion': _versionCtrl.text.trim(),
          'minVersion': _minVersionCtrl.text.trim().isNotEmpty ? _minVersionCtrl.text.trim() : _versionCtrl.text.trim(),
          'forceUpdate': _forceUpdate,
          'apkUrl': _apkUrlCtrl.text.trim(),
          'releaseNotes': _notesCtrl.text.trim(),
          'updateEnabled': _updateEnabled,
        },
      );
      ref.invalidate(adminUpdateConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update published!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Update Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.system_update_rounded, color: Color(0xFFD4AF37), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Publish App Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Set version, APK link, and release notes for users', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _versionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Latest Version *',
                      hintText: 'e.g. 1.2.0',
                      prefixIcon: Icon(Icons.tag, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minVersionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Min Version (optional)',
                      hintText: 'e.g. 1.0.0',
                      prefixIcon: Icon(Icons.low_priority, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apkUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'APK Download URL *',
                      hintText: 'https://your-server.com/app-release.apk',
                      prefixIcon: Icon(Icons.link, size: 20),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Release Notes',
                      hintText: 'Write release notes (one per line)',
                      prefixIcon: Icon(Icons.notes, size: 20),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Force Update', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _forceUpdate ? 'Users must update to continue' : 'Users can skip this update',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _forceUpdate,
                    activeColor: AppColors.error,
                    onChanged: (v) => setState(() => _forceUpdate = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Update Enabled', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _updateEnabled ? 'Update check is active' : 'Updates disabled',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _updateEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _updateEnabled = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.publish_rounded, size: 20),
                      label: Text(_saving ? 'Publishing...' : 'Publish Update'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF0A3D1F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current App Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ref.watch(currentVersionProvider).when(
                    data: (v) => _infoRow('Installed Version', 'v$v'),
                    loading: () => const Text('Loading...', style: TextStyle(color: AppColors.textSecondary)),
                    error: (_, __) => const Text('Unknown', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 8),
                  ref.watch(adminUpdateConfigProvider).when(
                    data: (config) {
                      if (config == null) return const Text('No update config found', style: TextStyle(color: AppColors.textHint));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Published Version', 'v${config.latestVersion}'),
                          _infoRow('Force Update', config.forceUpdate ? 'Yes' : 'No'),
                          _infoRow('Status', config.updateEnabled ? 'Active' : 'Disabled'),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const Text('Fetch error', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
