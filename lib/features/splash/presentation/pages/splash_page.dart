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
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final shouldNavigate = await _handleUpdateLogic();

    if (!mounted) return;
    if (shouldNavigate) {
      _navigateToApp();
    }
  }

  /// Core update logic. Returns true if user should proceed to app.
  Future<bool> _handleUpdateLogic() async {
    try {
      final updateService = ref.read(updateServiceProvider);
      final currentVersion = await UpdateService.getCurrentVersion();

      // ─── STEP 1: Detect post-update launch ───
      final isPostUpdate = await updateService.isPostUpdateLaunch();
      if (isPostUpdate) {
        // User just installed an update — record completion, skip all popups
        await updateService.recordUpdateCompleted();
        print('[Splash] Post-update launch detected for v$currentVersion — skipping popup');
        return true;
      }

      // ─── STEP 2: Always record current installed version ───
      await updateService.recordCurrentVersion(currentVersion);

      // ─── STEP 3: Smart check interval (don't spam API on rapid restarts) ───
      final shouldCheck = await updateService.shouldCheckForUpdate();
      if (!shouldCheck) return true;

      // ─── STEP 4: Fetch config from server ───
      final config = await updateService.checkForUpdate();
      await updateService.recordCheck();

      // If update system is disabled or config missing, proceed normally
      if (config == null || !config.updateEnabled) return true;

      // ─── STEP 5: Core rule — NEVER show popup if current >= latest ───
      if (UpdateService.isUpToDate(currentVersion, config)) {
        // User is already on latest version — no popup, ever
        return true;
      }

      // ─── STEP 6: Check if user already dismissed this exact version ───
      final lastDismissed = await updateService.getLastDismissedVersion();
      if (lastDismissed == config.latestVersion) {
        // User already dismissed this version — don't nag them again
        // But still check if it's a force update (force overrides dismiss)
        if (!config.forceUpdate && !UpdateService.isBelowMinVersion(currentVersion, config)) {
          return true;
        }
      }

      // ─── STEP 7: Determine if force update ───
      final isForce = config.forceUpdate ||
          UpdateService.isBelowMinVersion(currentVersion, config);

      final effectiveConfig = AppUpdateConfig(
        latestVersion: config.latestVersion,
        minVersion: config.minVersion,
        forceUpdate: isForce,
        apkUrl: config.apkUrl,
        releaseNotes: config.releaseNotes,
        updateEnabled: config.updateEnabled,
        showUpdateToOutdatedUsers: config.showUpdateToOutdatedUsers,
      );

      if (!mounted) return true;

      // ─── STEP 8: Show appropriate dialog ───
      if (isForce) {
        // Force update: block until user installs new version
        await _showForceBlockingDialog(effectiveConfig);
        return false;
      } else {
        // Optional update: show dialog, let user dismiss
        bool dismissed = false;
        await UpdateDialog.show(context, effectiveConfig, onLater: () {
          dismissed = true;
          updateService.recordDismissedVersion(config.latestVersion);
        });
        return dismissed;
      }
    } catch (e) {
      // On error, let user through — never block on network failure
      print('[Splash] Update check error: $e');
      return true;
    }
  }

  /// Force update loop: blocks until installed version matches latest.
  Future<void> _showForceBlockingDialog(AppUpdateConfig config) async {
    while (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: UpdateDialog(
            config: config,
            onLater: null,
          ),
        ),
      );

      // After dialog closes (user attempted install), wait and re-check
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final currentVersion = await UpdateService.getCurrentVersion();
      final stillNeedsUpdate = UpdateService.isUpdateAvailable(currentVersion, config);

      if (!stillNeedsUpdate) {
        // User successfully updated — record it
        await ref.read(updateServiceProvider).recordUpdateCompleted();
        return;
      }
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

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFD4AF37)),
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
      ),
    );
  }
}
