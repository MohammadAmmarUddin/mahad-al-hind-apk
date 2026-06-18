import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
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
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('settings'))),
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
          _SectionHeader(t.translate('account')),
          _SettingsTile(icon: Icons.person_outline, title: t.translate('editProfile'), onTap: () => context.push('/more/profile/edit')),
          _SettingsTile(icon: Icons.lock_outline, title: t.translate('changePassword'), onTap: () => _showChangePasswordDialog(context, t)),
          const SizedBox(height: 16),
          _SectionHeader(t.translate('darkMode').replaceAll(' (ON)', '').replaceAll(' (OFF)', '')),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.textSecondary),
            title: Text(isDark ? '${t.translate('darkMode')} (ON)' : '${t.translate('darkMode')} (OFF)'),
            value: isDark,
            onChanged: (_) => ref.read(themeProvider).toggleTheme(),
            activeThumbColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          _SectionHeader(t.translate('language')),
          _SettingsTile(
            icon: Icons.language,
            title: t.translate('language'),
            subtitle: currentLocale.languageCode == 'bn' ? 'বাংলা' : 'English',
            onTap: () => _showLanguageDialog(context, ref, currentLocale, t),
          ),
          const SizedBox(height: 16),
          _SectionHeader(t.translate('help')),
          _SettingsTile(icon: Icons.help_outline, title: t.translate('help'), onTap: () {}),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: t.translate('privacy'), onTap: () {}),
          _SettingsTile(icon: Icons.info_outline, title: t.translate('about'), onTap: () => _showAboutDialog(context, t)),
          const SizedBox(height: 24),
          _SettingsTile(
            icon: Icons.logout,
            title: t.translate('logout'),
            color: AppColors.error,
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('${t.translate('version')} 1.0.0', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, Locale current, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('language')),
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
              title: const Text('বাংলা'),
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

  void _showChangePasswordDialog(BuildContext context, AppLocalizations t) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('changePassword')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: currentController, obscureText: true, decoration: InputDecoration(hintText: t.translate('currentPassword'))),
              const SizedBox(height: 12),
              TextField(controller: newController, obscureText: true, decoration: InputDecoration(hintText: t.translate('newPasswordLabel'))),
              const SizedBox(height: 12),
              TextField(controller: confirmController, obscureText: true, decoration: InputDecoration(hintText: t.translate('confirmPassword'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.translate('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.translate('save'))),
              );
            },
            child: Text(t.translate('save')),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations t) {
    showAboutDialog(
      context: context,
      applicationName: "Ma'hadul Qiraat Al Hind",
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          AppAssets.logo,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.mosque, color: Colors.white, size: 28),
          ),
        ),
      ),
      children: [
        Text(t.translate('app_tagline')),
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
