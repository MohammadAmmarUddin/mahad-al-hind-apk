import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/hive_storage.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.menu_book_rounded,
      titleKey: 'onboardingTitle1',
      descKey: 'onboardingDesc1',
      gradient: [AppColors.primary, AppColors.primaryLight],
    ),
    _OnboardingData(
      icon: Icons.analytics_rounded,
      titleKey: 'onboardingTitle2',
      descKey: 'onboardingDesc2',
      gradient: [AppColors.secondary, Color(0xFF5EEAD4)],
    ),
    _OnboardingData(
      icon: Icons.headphones_rounded,
      titleKey: 'onboardingTitle3',
      descKey: 'onboardingDesc3',
      gradient: [AppColors.accent, AppColors.accentLight],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    HiveStorage.saveSetting('is_first_time', false);
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Container(
                padding: const EdgeInsets.all(AppDimens.paddingXl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        page.icon,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _getLocalizedTitle(page.titleKey),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getLocalizedDesc(page.descKey),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          // Skip Button
          Positioned(
            top: 48,
            right: 16,
            child: SafeArea(
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Page Indicator & Next
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.paddingXl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next/Get Started Button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: TextStyle(
                              color: _pages[_currentPage].gradient[0],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: _pages[_currentPage].gradient[0],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle(String key) {
    const titles = {
      'onboardingTitle1': 'Learn Quran & Islamic Studies',
      'onboardingTitle2': 'Track Your Progress',
      'onboardingTitle3': 'Listen & Watch',
    };
    return titles[key] ?? key;
  }

  String _getLocalizedDesc(String key) {
    const descs = {
      'onboardingDesc1':
          'Access comprehensive courses taught by renowned scholars from around the world.',
      'onboardingDesc2':
          'Monitor your learning journey with detailed progress analytics and certificates.',
      'onboardingDesc3':
          'Stream Tilawah, Bayan, and lectures anywhere, anytime with premium quality.',
    };
    return descs[key] ?? key;
  }
}

class _OnboardingData {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final List<Color> gradient;

  const _OnboardingData({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.gradient,
  });
}
