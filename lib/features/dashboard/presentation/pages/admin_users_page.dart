import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});
  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/user/allUsers');
      final data = res.data;
      List<dynamic> users = [];
      if (data is List) {
        users = data;
      } else if (data is Map) {
        if (data['data'] is List) users = data['data'];
        else if (data['users'] is List) users = data['users'];
      }
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<dynamic> get _filteredUsers {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) {
      final name = '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'.toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  void _showEditUserDialog(dynamic user) {
    final fnCtrl = TextEditingController(text: user['firstname'] ?? '');
    final lnCtrl = TextEditingController(text: user['lastname'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final imgCtrl = TextEditingController(text: user['img'] ?? '');
    String role = user['role'] ?? 'student';
    bool isSuspended = user['isSuspended'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                backgroundImage: (user['img'] != null && (user['img'] as String).isNotEmpty)
                    ? NetworkImage(user['img'])
                    : null,
                child: (user['img'] == null || (user['img'] as String).isEmpty)
                    ? Text(
                        '${(user['firstname'] ?? 'U')[0]}'.toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Edit User', style: const TextStyle(fontSize: 18))),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: fnCtrl, decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 8),
                TextField(controller: lnCtrl, decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 8),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 8),
                TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Profile Image URL', prefixIcon: Icon(Icons.image_outlined))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
                  items: ['student', 'admin', 'teacher'].map((r) => DropdownMenuItem(
                    value: r,
                    child: Row(
                      children: [
                        Icon(
                          r == 'admin' ? Icons.admin_panel_settings : r == 'teacher' ? Icons.school : Icons.person,
                          size: 16,
                          color: r == 'admin' ? AppColors.error : r == 'teacher' ? AppColors.accent : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(r[0].toUpperCase() + r.substring(1)),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => role = v); },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Suspended'),
                  subtitle: Text(isSuspended ? 'User is suspended' : 'User is active'),
                  value: isSuspended,
                  onChanged: (v) => setDialogState(() => isSuspended = v),
                  activeThumbColor: AppColors.error,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(dioClientProvider).patch(
                    '/api/user/updateUser/${user['_id']}',
                    data: {
                      'firstname': fnCtrl.text.trim(),
                      'lastname': lnCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'img': imgCtrl.text.trim(),
                      'role': role,
                      'isSuspended': isSuspended,
                    },
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated ${fnCtrl.text}'), backgroundColor: AppColors.success),
                    );
                    _fetchUsers();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
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

  void _showUserDetails(dynamic user) {
    final fn = user['firstname'] ?? '';
    final ln = user['lastname'] ?? '';
    final role = user['role'] ?? 'student';
    final isSuspended = user['isSuspended'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage: (user['img'] != null && (user['img'] as String).isNotEmpty)
                      ? NetworkImage(user['img'])
                      : null,
                  child: (user['img'] == null || (user['img'] as String).isEmpty)
                      ? Text('${fn.isNotEmpty ? fn[0] : 'U'}'.toUpperCase(),
                          style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('$fn $ln', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'admin' ? AppColors.error.withOpacity(0.1) : role == 'teacher' ? AppColors.accent.withOpacity(0.1) : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(role.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: role == 'admin' ? AppColors.error : role == 'teacher' ? AppColors.accent : AppColors.primary)),
                ),
              ),
              if (isSuspended) ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('SUSPENDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _detailRow(Icons.email_outlined, 'Email', user['email'] ?? 'N/A'),
              _detailRow(Icons.phone_outlined, 'Phone', user['phone'] ?? 'N/A'),
              _detailRow(Icons.badge_outlined, 'User ID', user['_id'] ?? 'N/A'),
              _detailRow(Icons.language, 'Language', user['preferredLanguage'] ?? 'en'),
              _detailRow(Icons.calendar_today, 'Joined', user['createdAt'] ?? 'N/A'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditUserDialog(user);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _toggleSuspend(user);
                      },
                      icon: Icon(isSuspended ? Icons.check_circle_outline : Icons.block, size: 16),
                      label: Text(isSuspended ? 'Unsuspend' : 'Suspend'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isSuspended ? AppColors.success : AppColors.error,
                        side: BorderSide(color: isSuspended ? AppColors.success : AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSuspend(dynamic user) async {
    final isSuspended = user['isSuspended'] ?? false;
    try {
      await ref.read(dioClientProvider).patch(
        '/api/user/updateUser/${user['_id']}',
        data: {'isSuspended': !isSuspended},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuspended ? 'User unsuspended' : 'User suspended'),
            backgroundColor: isSuspended ? AppColors.success : AppColors.error,
          ),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _countChip('Total', _users.length, AppColors.primary),
                const SizedBox(width: 8),
                _countChip('Admin', _users.where((u) => u['role'] == 'admin').length, AppColors.error),
                const SizedBox(width: 8),
                _countChip('Students', _users.where((u) => u['role'] == 'student').length, AppColors.success),
                const SizedBox(width: 8),
                _countChip('Suspended', _users.where((u) => u['isSuspended'] == true).length, AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(_search.isNotEmpty ? 'No users match search' : 'No users found', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: users.length,
                          itemBuilder: (ctx, i) {
                            final u = users[i];
                            final fn = u['firstname'] ?? '';
                            final ln = u['lastname'] ?? '';
                            final name = '$fn $ln'.trim();
                            final role = u['role'] ?? 'student';
                            final isSuspended = u['isSuspended'] ?? false;
                            final isAdmin = role == 'admin';
                            final isTeacher = role == 'teacher';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: () => _showUserDetails(u),
                                onLongPress: () => _showEditUserDialog(u),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isAdmin
                                          ? AppColors.error.withOpacity(0.1)
                                          : isTeacher
                                              ? AppColors.accent.withOpacity(0.1)
                                              : AppColors.primarySurface,
                                      backgroundImage: (u['img'] != null && (u['img'] as String).isNotEmpty)
                                          ? NetworkImage(u['img'])
                                          : null,
                                      child: (u['img'] == null || (u['img'] as String).isEmpty)
                                          ? Text(
                                              '${name.isNotEmpty ? name[0] : 'U'}'.toUpperCase(),
                                              style: TextStyle(
                                                color: isAdmin
                                                    ? AppColors.error
                                                    : isTeacher
                                                        ? AppColors.accent
                                                        : AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (isSuspended)
                                      Positioned(
                                        bottom: 0, right: 0,
                                        child: Container(
                                          width: 14, height: 14,
                                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                          child: const Icon(Icons.block, color: Colors.white, size: 8),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? AppColors.error.withOpacity(0.1)
                                            : isTeacher
                                                ? AppColors.accent.withOpacity(0.1)
                                                : AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isAdmin
                                              ? AppColors.error
                                              : isTeacher
                                                  ? AppColors.accent
                                                  : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['email'] ?? '', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    if (u['phone'] != null && (u['phone'] as String).isNotEmpty)
                                      Text(u['phone'], style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                                    PopupMenuItem(
                                      value: 'role',
                                      child: Row(children: [
                                        Icon(Icons.admin_panel_settings, size: 16, color: AppColors.accent),
                                        const SizedBox(width: 8),
                                        Text('Make ${isAdmin ? 'Student' : 'Admin'}'),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: 'suspend',
                                      child: Row(children: [
                                        Icon(isSuspended ? Icons.check_circle_outline : Icons.block, size: 16,
                                            color: isSuspended ? AppColors.success : AppColors.error),
                                        const SizedBox(width: 8),
                                        Text(isSuspended ? 'Unsuspend' : 'Suspend',
                                            style: TextStyle(color: isSuspended ? AppColors.success : AppColors.error)),
                                      ]),
                                    ),
                                  ],
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      _showEditUserDialog(u);
                                    } else if (val == 'role') {
                                      final newRole = isAdmin ? 'student' : 'admin';
                                      try {
                                        await ref.read(dioClientProvider).patch(
                                          '/api/user/updateUser/${u['_id']}',
                                          data: {'role': newRole},
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Role changed to $newRole'), backgroundColor: AppColors.success),
                                          );
                                          _fetchUsers();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                          );
                                        }
                                      }
                                    } else if (val == 'suspend') {
                                      _toggleSuspend(u);
                                    }
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

  Widget _countChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}
