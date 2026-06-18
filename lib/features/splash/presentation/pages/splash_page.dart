import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/models/app_update_config.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/services/update_provider.dart';
import '../../../../core/widgets/update_dialog.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _controller.addListener(() {
      setState(() {
        _progress = _controller.value;
      });
    });

    _controller.forward();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    bool navigatedFromDialog = false;

    try {
      final config = await ref.read(updateServiceProvider).checkForUpdate();
      final currentVersion = await UpdateService.getCurrentVersion();

      if (config != null &&
          UpdateService.isUpdateAvailable(currentVersion, config)) {
        if (!mounted) return;

        final isForce = config.forceUpdate ||
            UpdateService.isBelowMinVersion(currentVersion, config);

        final effectiveConfig = AppUpdateConfig(
          latestVersion: config.latestVersion,
          minVersion: config.minVersion,
          forceUpdate: isForce,
          apkUrl: config.apkUrl,
          releaseNotes: config.releaseNotes,
          updateEnabled: config.updateEnabled,
        );

        if (isForce) {
          await UpdateDialog.show(context, effectiveConfig);
          if (mounted) _initAndNavigate();
          return;
        } else {
          await UpdateDialog.show(context, effectiveConfig, onLater: () {
            navigatedFromDialog = true;
            _navigateToApp();
          });
        }
      }
    } catch (_) {}

    if (!mounted) return;
    if (!navigatedFromDialog) {
      _navigateToApp();
    }
  }

  void _navigateToApp() {
    final isFirstTime =
        HiveStorage.getSetting('is_first_time', defaultValue: true);
    if (isFirstTime == true) {
      HiveStorage.saveSetting('is_first_time', false);
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A3D1F),
              Color(0xFF0E5C28),
              Color(0xFF1B7A3D),
              Color(0xFF0A3D1F),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.25,
              left: -size.width * 0.15,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.logo,
                    width: size.shortestSide * 0.35,
                    height: size.shortestSide * 0.35,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: size.shortestSide * 0.35,
                      height: size.shortestSide * 0.35,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.mosque_rounded,
                        size: 70,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: size.width * 0.5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 5,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Ma'hadul Qiraat Al Hind",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
