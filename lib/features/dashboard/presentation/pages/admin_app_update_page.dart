import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_update_config.dart';
import '../../../../core/network/api_endpoints.dart';
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
  bool _showUpdateToOutdatedUsers = false;
  bool _saving = false;
  bool _hasExistingConfig = false;
  String? _lastSavedField;
  DateTime? _lastSavedTime;

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
          _hasExistingConfig = true;
          _forceUpdate = config.forceUpdate;
          _updateEnabled = config.updateEnabled;
          _showUpdateToOutdatedUsers = config.showUpdateToOutdatedUsers;
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

  void _showSavedIndicator(String field) {
    setState(() {
      _lastSavedField = field;
      _lastSavedTime = DateTime.now();
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _lastSavedField == field) {
        setState(() { _lastSavedField = null; _lastSavedTime = null; });
      }
    });
  }

  /// Instant toggle save — uses the main PATCH endpoint which accepts partial updates
  Future<void> _saveToggles({String? field}) async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.ensureTokenLoaded();
      await dio.patch(
        ApiEndpoints.adminAppUpdate,
        data: {
          'forceUpdate': _forceUpdate,
          'updateEnabled': _updateEnabled,
          'showUpdateToOutdatedUsers': _showUpdateToOutdatedUsers,
        },
      );
      ref.invalidate(adminUpdateConfigProvider);
      if (mounted && field != null) _showSavedIndicator(field);
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

  /// Full save — version, apkUrl, notes + toggles
  Future<void> _saveAll() async {
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
      final dio = ref.read(dioClientProvider);
      await dio.ensureTokenLoaded();
      await dio.patch(
        ApiEndpoints.adminAppUpdate,
        data: {
          'latestVersion': _versionCtrl.text.trim(),
          'minVersion': _minVersionCtrl.text.trim().isNotEmpty ? _minVersionCtrl.text.trim() : _versionCtrl.text.trim(),
          'apkUrl': _apkUrlCtrl.text.trim(),
          'releaseNotes': _notesCtrl.text.trim(),
          'forceUpdate': _forceUpdate,
          'updateEnabled': _updateEnabled,
          'showUpdateToOutdatedUsers': _showUpdateToOutdatedUsers,
        },
      );
      ref.invalidate(adminUpdateConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update config saved!'), backgroundColor: AppColors.success),
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

  Widget _savedBadge(String field) {
    if (_lastSavedField != field) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: AppColors.success),
          SizedBox(width: 4),
          Text('Saved', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Update Management'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── LIVE TOGGLES (auto-save, no publish needed) ───
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.toggle_on, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Live Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Auto-save', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Changes apply instantly across all devices', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),

                  // Update Enabled
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        const Text('Update Enabled', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        _savedBadge('updateEnabled'),
                      ],
                    ),
                    subtitle: Text(
                      _updateEnabled ? 'Update check is active — users will be notified of new versions' : 'Updates disabled — app behaves normally, no checks',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _updateEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) { setState(() => _updateEnabled = v); _saveToggles(field: 'updateEnabled'); },
                  ),
                  const Divider(height: 1),

                  // Show to outdated users
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        const Text('Show to Outdated Users', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        _savedBadge('showUpdateToOutdatedUsers'),
                      ],
                    ),
                    subtitle: Text(
                      _showUpdateToOutdatedUsers ? 'Only users running an older version will see update prompts' : 'No update prompts shown even if newer version exists',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _showUpdateToOutdatedUsers,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) { setState(() => _showUpdateToOutdatedUsers = v); _saveToggles(field: 'showUpdateToOutdatedUsers'); },
                  ),
                  const Divider(height: 1),

                  // Force Update
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        const Text('Force Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        _savedBadge('forceUpdate'),
                      ],
                    ),
                    subtitle: Text(
                      _forceUpdate
                          ? 'Blocks access on next launch until user updates (never interrupts active sessions)'
                          : 'Optional update — users may choose "Later"',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _forceUpdate,
                    activeThumbColor: AppColors.error,
                    onChanged: (v) { setState(() => _forceUpdate = v); _saveToggles(field: 'forceUpdate'); },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── VERSION & APK CONFIG ───
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
                      const Expanded(child: Text('Version Config', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Set version, APK link, and release notes', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _versionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Latest Version *',
                      hintText: 'e.g. 1.3.0',
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
                      hintText: 'https://github.com/.../app-release.apk',
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveAll,
                      icon: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(_saving ? 'Saving...' : 'Save Version Config'),
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

          // ─── CURRENT STATUS ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                          _infoRow('Update Enabled', config.updateEnabled ? 'Active' : 'Disabled'),
                          _infoRow('Show to Outdated', config.showUpdateToOutdatedUsers ? 'Yes' : 'No'),
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
