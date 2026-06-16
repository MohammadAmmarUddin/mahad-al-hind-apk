import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../main.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider).isDark;
    final currentLocale = ref.watch(localeProvider).locale;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (user.firstname ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(user.email ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: user.role == 'admin' ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (user.role ?? 'student').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: user.role == 'admin' ? AppColors.error : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          const _SectionHeader('Account'),
          _SettingsTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () => context.push('/more/profile/edit')),
          _SettingsTile(icon: Icons.lock_outline, title: 'Change Password', onTap: () => _showChangePasswordDialog(context)),
          const SizedBox(height: 16),
          const _SectionHeader('Appearance'),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.textSecondary),
            title: Text(isDark ? 'Dark Mode (ON)' : 'Dark Mode (OFF)'),
            value: isDark,
            onChanged: (_) => ref.read(themeProvider).toggleTheme(),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Language'),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: currentLocale.languageCode == 'bn' ? 'Bengali' : 'English',
            onTap: () => _showLanguageDialog(context, ref, currentLocale),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Support'),
          _SettingsTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
          _SettingsTile(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
          _SettingsTile(icon: Icons.info_outline, title: 'About', onTap: () => _showAboutDialog(context)),
          const SizedBox(height: 24),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            color: AppColors.error,
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Version 1.0.0', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, Locale current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: current.languageCode,
              onChanged: (v) {
                ref.read(localeProvider).setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: const Text('Bengali'),
              value: 'bn',
              groupValue: current.languageCode,
              onChanged: (v) {
                ref.read(localeProvider).setLocale(const Locale('bn'));
                Navigator.pop(ctx);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: currentController, obscureText: true, decoration: const InputDecoration(hintText: 'Current Password')),
              const SizedBox(height: 12),
              TextField(controller: newController, obscureText: true, decoration: const InputDecoration(hintText: 'New Password')),
              const SizedBox(height: 12),
              TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm Password')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully!')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "Ma'hadul Qiraat Al Hind",
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.mosque, color: Colors.white, size: 28),
      ),
      children: [
        const Text('A comprehensive Islamic educational ecosystem.'),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({required this.icon, required this.title, this.subtitle, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
