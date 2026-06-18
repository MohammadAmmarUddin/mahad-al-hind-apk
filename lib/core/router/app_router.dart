import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/courses/presentation/pages/courses_page.dart';
import '../../features/courses/presentation/pages/course_detail_page.dart';
import '../../features/audio_library/presentation/pages/audio_library_page.dart';
import '../../features/audio_library/presentation/pages/audio_player_page.dart';
import '../../features/audio_library/presentation/pages/audio_category_detail_page.dart';
import '../../features/videos/presentation/pages/videos_page.dart';
import '../../features/videos/presentation/pages/video_player_page.dart';
import '../../features/shayekh/presentation/pages/shayekh_page.dart';
import '../../features/shayekh/presentation/pages/shayekh_detail_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/fees/presentation/pages/fees_page.dart';
import '../../features/certificates/presentation/pages/certificates_page.dart';
import '../../features/certificates/presentation/pages/certificate_verify_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/gallery/presentation/pages/gallery_page.dart';
import '../../features/gallery/presentation/pages/gallery_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/admin_videos_page.dart';
import '../../features/dashboard/presentation/pages/admin_audio_page.dart';
import '../../features/dashboard/presentation/pages/admin_gallery_page.dart';
import '../../features/dashboard/presentation/pages/admin_courses_page.dart';
import '../../features/dashboard/presentation/pages/admin_notifications_page.dart';
import '../../features/dashboard/presentation/pages/admin_users_page.dart';
import '../../features/dashboard/presentation/pages/admin_enrollments_page.dart';
import '../../features/dashboard/presentation/pages/admin_payments_page.dart';
import '../../features/dashboard/presentation/pages/admin_site_content_page.dart';
import '../../features/dashboard/presentation/pages/admin_certificates_page.dart';
import '../../features/dashboard/presentation/pages/admin_app_update_page.dart';
import '../../features/dashboard/presentation/pages/admin_news_feed_page.dart';
import '../../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../features/more/presentation/pages/more_page.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (context, state) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/courses', builder: (context, state) => const CoursesPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/audio', builder: (context, state) => const AudioLibraryPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
                routes: [
                  GoRoute(path: 'notifications', builder: (_, __) => const NotificationsPage()),
                  GoRoute(path: 'videos', builder: (_, __) => const VideosPage()),
                  GoRoute(path: 'videos/player', builder: (_, __) => const VideoPlayerPage()),
                  GoRoute(path: 'gallery', builder: (_, __) => const GalleryPage()),
                  GoRoute(path: 'gallery/:id', builder: (_, s) {
                    final item = s.extra as Map<String, dynamic>?;
                    return GalleryDetailPage(galleryId: s.pathParameters['id'] ?? '', item: item);
                  }),
                  GoRoute(path: 'shayekh', builder: (_, __) => const ShayekhPage()),
                  GoRoute(path: 'shayekh/:id', builder: (_, s) => ShayekhDetailPage(shayekhId: s.pathParameters['id'] ?? '')),
                  GoRoute(path: 'attendance', builder: (_, __) => const AttendancePage()),
                  GoRoute(path: 'fees', builder: (_, __) => const FeesPage()),
                  GoRoute(path: 'certificates', builder: (_, __) => const CertificatesPage()),
                  GoRoute(path: 'certificates/verify', builder: (_, s) => CertificateVerifyPage(certificateId: s.uri.queryParameters['id'] ?? '')),
                  GoRoute(path: 'profile', builder: (_, __) => const ProfilePage()),
                  GoRoute(path: 'profile/edit', builder: (_, __) => const EditProfilePage()),
                  GoRoute(path: 'settings', builder: (_, __) => const SettingsPage()),
                  GoRoute(path: 'dashboard', builder: (_, __) => const DashboardPage()),
                  GoRoute(path: 'ai-assistant', builder: (_, __) => const AiAssistantPage()),
                  // Admin routes
                  GoRoute(path: 'admin/videos', builder: (_, __) => const AdminVideosPage()),
                  GoRoute(path: 'admin/audio', builder: (_, __) => const AdminAudioPage()),
                  GoRoute(path: 'admin/gallery', builder: (_, __) => const AdminGalleryPage()),
                  GoRoute(path: 'admin/courses', builder: (_, __) => const AdminCoursesPage()),
                  GoRoute(path: 'admin/notifications', builder: (_, __) => const AdminNotificationsPage()),
                  GoRoute(path: 'admin/users', builder: (_, __) => const AdminUsersPage()),
                  GoRoute(path: 'admin/enrollments', builder: (_, __) => const AdminEnrollmentsPage()),
                  GoRoute(path: 'admin/payments', builder: (_, __) => const AdminPaymentsPage()),
                  GoRoute(path: 'admin/site-content', builder: (_, __) => const AdminSiteContentPage()),
                  GoRoute(path: 'admin/certificates', builder: (_, __) => const AdminCertificatesPage()),
                  GoRoute(path: 'admin/news-feed', builder: (_, __) => const AdminNewsFeedPage()),
                  GoRoute(path: 'admin/app-update', builder: (_, __) => const AdminAppUpdatePage()),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/splash', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/login', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const SignupPage()),
      GoRoute(path: '/forgot-password', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: '/course/:id', parentNavigatorKey: _rootNavigatorKey, builder: (_, s) => CourseDetailPage(courseId: s.pathParameters['id'] ?? '')),
      GoRoute(path: '/audio/player', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const AudioPlayerPage()),
      GoRoute(path: '/audio/category/:id', parentNavigatorKey: _rootNavigatorKey, builder: (_, s) => AudioCategoryDetailPage(categoryId: s.pathParameters['id'] ?? '')),
      GoRoute(
        path: '/verify-certificate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => CertificateVerifyPage(
          certificateId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
    ],
    redirect: (context, state) {
      final isOnLogin = state.matchedLocation == '/login';
      final isOnSignup = state.matchedLocation == '/signup';
      final isAuth = ref.read(authStateProvider).valueOrNull ?? false;
      if (isAuth && (isOnLogin || isOnSignup)) return '/';
      return null;
    },
  );
});
