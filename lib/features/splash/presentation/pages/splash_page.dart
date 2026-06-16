import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/models/app_update_config.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/services/update_provider.dart';
import '../../../../core/widgets/update_dialog.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/providers/core_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.elasticOut)),
    );

    _controller.addListener(() {
      setState(() { _progress = _controller.value; });
    });

    _controller.forward();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check for update
    try {
      final dio = ref.read(dioClientProvider);
      final pkgInfo = await PackageInfo.fromPlatform();
      final currentVersion = pkgInfo.version;

      final response = await dio.get('/api/app/version');
      final data = response.data;

      AppUpdateConfig? config;
      if (data is Map && data['data'] is Map) {
        config = AppUpdateConfig.fromJson(Map<String, dynamic>.from(data['data']));
      } else if (data is Map && data['latestVersion'] != null) {
        config = AppUpdateConfig.fromJson(Map<String, dynamic>.from(data));
      }

      if (config != null &&
          config.updateEnabled &&
          config.latestVersion.isNotEmpty &&
          UpdateService.compareVersions(currentVersion, config.latestVersion) < 0) {

        if (!mounted) return;
        await UpdateDialog.show(context, config, onLater: () {
          _navigateToApp();
        });
      }
    } catch (_) {
      // No network or update check failed — proceed normally
    }

    if (!mounted) return;
    _navigateToApp();
  }

  void _navigateToApp() {
    final isFirstTime = HiveStorage.getSetting('is_first_time', defaultValue: true);
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
                  color: Colors.white.withOpacity(0.04),
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
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoFade.value,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/golden22full.png',
                      width: size.width * 0.55,
                      height: size.width * 0.55,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.mosque_rounded, size: 70, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: size.width * 0.55,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Ma'hadul Qiraat Al Hind",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Islamic Educational Ecosystem',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFD4AF37),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
