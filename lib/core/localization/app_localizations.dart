import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('bn')];

  Map<String, String> get _localizedStrings {
    switch (locale.languageCode) {
      case 'bn':
        return _bengaliStrings;
      default:
        return _englishStrings;
    }
  }

  String translate(String key) => _localizedStrings[key] ?? key;

  // ==================== English Strings ====================
  static const Map<String, String> _englishStrings = {
    // General
    'app_name': "Ma'hadul Qiraat Al Hind",
    'app_tagline': 'Modern Islamic Learning & Institute Management',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'submit': 'Submit',
    'close': 'Close',
    'search': 'Search',
    'filter': 'Filter',
    'sort': 'Sort',
    'refresh': 'Refresh',
    'viewAll': 'View All',
    'seeMore': 'See More',
    'seeLess': 'See Less',
    'noData': 'No data available',
    'somethingWentWrong': 'Something went wrong',

    // Navigation
    'nav_home': 'Home',
    'nav_courses': 'Courses',
    'nav_audio': 'Audio',
    'nav_more': 'More',

    // Auth
    'login': 'Login',
    'signup': 'Sign Up',
    'logout': 'Logout',
    'email': 'Email',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'forgotPassword': 'Forgot Password?',
    'resetPassword': 'Reset Password',
    'loginWithGoogle': 'Login with Google',
    'orContinueWith': 'Or continue with',
    'dontHaveAccount': "Don't have an account?",
    'alreadyHaveAccount': 'Already have an account?',
    'createAccount': 'Create Account',
    'welcomeBack': 'Welcome Back!',
    'loginSubtitle': 'Sign in to continue learning',
    'signupSubtitle': 'Start your Islamic learning journey',
    'rememberMe': 'Remember Me',
    'otpVerification': 'OTP Verification',
    'enterOtp': 'Enter the OTP sent to your email',
    'verify': 'Verify',
    'resendOtp': 'Resend OTP',
    'newPassword': 'New Password',
    'passwordResetSuccess': 'Password reset successful!',
    'loginSuccess': 'Welcome back!',
    'signupSuccess': 'Account created successfully!',
    'invalidCredentials': 'Invalid email or password',
    'emailRequired': 'Email is required',
    'passwordRequired': 'Password is required',
    'invalidEmail': 'Invalid email address',
    'passwordTooShort': 'Password must be at least 8 characters',
    'passwordsDoNotMatch': 'Passwords do not match',

    // Home
    'home': 'Home',
    'featuredCourses': 'Featured Courses',
    'shayekhSpotlight': 'Shayekh Spotlight',
    'audioLibrary': 'Audio Library',
    'latestVideos': 'Latest Videos',
    'testimonials': 'Testimonials',
    'studentGallery': 'Student Gallery',
    'announcements': 'Announcements',
    'totalStudents': 'Total Students',
    'totalCourses': 'Total Courses',
    'totalShayekh': 'Total Shayekh',
    'coursesCompleted': 'Courses Completed',

    // Courses
    'allCourses': 'All Courses',
    'courseCategories': 'Course Categories',
    'enrollNow': 'Enroll Now',
    'enrolled': 'Enrolled',
    'courseDetails': 'Course Details',
    'curriculum': 'Curriculum',
    'lessons': 'Lessons',
    'students': 'Students',
    'rating': 'Rating',
    'reviews': 'Reviews',
    'relatedCourses': 'Related Courses',
    'aboutCourse': 'About Course',
    'instructor': 'Instructor',
    'duration': 'Duration',
    'level': 'Level',
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
    'free': 'Free',
    'paid': 'Paid',
    'searchCourses': 'Search courses...',
    'noCoursesFound': 'No courses found',

    // Audio
    'audioLibraryTitle': 'Audio Library',
    'nowPlaying': 'Now Playing',
    'playlists': 'Playlists',
    'favorites': 'Favorites',
    'recentlyPlayed': 'Recently Played',
    'downloads': 'Downloads',
    'sleepTimer': 'Sleep Timer',
    'playbackSpeed': 'Playback Speed',
    'addToFavorites': 'Add to Favorites',
    'removeFromFavorites': 'Remove from Favorites',
    'queue': 'Queue',
    'noAudioFound': 'No audio content found',

    // Videos
    'videoLibrary': 'Video Library',
    'watchNow': 'Watch Now',
    'continueWatching': 'Continue Watching',
    'noVideosFound': 'No videos found',

    // Attendance
    'attendance': 'Attendance',
    'monthlyReport': 'Monthly Report',
    'attendancePercentage': 'Attendance Percentage',
    'present': 'Present',
    'absent': 'Absent',
    'late': 'Late',
    'excused': 'Excused',

    // Fees
    'feeManagement': 'Fee Management',
    'dueAmount': 'Due Amount',
    'paymentHistory': 'Payment History',
    'payNow': 'Pay Now',
    'admissionFee': 'Admission Fee',
    'monthlyFee': 'Monthly Fee',
    'examFee': 'Exam Fee',
    'hostelFee': 'Hostel Fee',
    'libraryFee': 'Library Fee',
    'totalPaid': 'Total Paid',
    'totalDue': 'Total Due',

    // Certificates
    'myCertificates': 'My Certificates',
    'verifyCertificate': 'Verify Certificate',
    'certificateId': 'Certificate ID',
    'issuedOn': 'Issued On',
    'noCertificates': 'No certificates earned yet',
    'scanQR': 'Scan QR Code',
    'shareCertificate': 'Share Certificate',

    // Notifications
    'notifications': 'Notifications',
    'markAllRead': 'Mark all read',
    'noNotifications': 'No notifications yet',

    // Profile
    'profile': 'Profile',
    'editProfile': 'Edit Profile',
    'changePassword': 'Change Password',
    'settings': 'Settings',
    'language': 'Language',
    'darkMode': 'Dark Mode',
    'currentPassword': 'Current Password',
    'newPasswordLabel': 'New Password',
    'account': 'Account',
    'privacy': 'Privacy',
    'help': 'Help & Support',
    'about': 'About',
    'version': 'Version',
    'deleteAccount': 'Delete Account',
    'deleteAccountConfirm': 'Are you sure you want to delete your account? This action cannot be undone.',

    // Gallery
    'gallery': 'Gallery',
    'photos': 'Photos',
    'noGalleryItems': 'No gallery items found',

    // Shayekh
    'shayekh': 'Shayekh',
    'shayekhDetails': 'Shayekh Details',
    'specialization': 'Specialization',
    'country': 'Country',
    'coursesTaught': 'Courses Taught',
    'follow': 'Follow',
    'unfollow': 'Unfollow',

    // Onboarding
    'getStarted': 'Get Started',
    'next': 'Next',
    'skip': 'Skip',
    'onboardingTitle1': 'Learn Quran & Islamic Studies',
    'onboardingDesc1': 'Access comprehensive courses taught by renowned scholars from around the world.',
    'onboardingTitle2': 'Track Your Progress',
    'onboardingDesc2': 'Monitor your learning journey with detailed progress analytics and certificates.',
    'onboardingTitle3': 'Listen & Watch',
    'onboardingDesc3': 'Stream Tilawah, Bayan, and lectures anywhere, anytime with premium quality.',

    // Dashboard
    'dashboard': 'Dashboard',
    'overview': 'Overview',
    'manageStudents': 'Manage Students',
    'manageCourses': 'Manage Courses',
    'manageAttendance': 'Manage Attendance',
    'manageFees': 'Manage Fees',
    'reports': 'Reports',

    // AI Assistant
    'aiAssistant': 'AI Assistant',
    'askAnything': 'Ask anything about the institute...',
    'aiNotAvailable': 'AI Assistant coming soon!',

    // Extra
    'myCourses': 'My Courses',
    'batch': 'Batch',
    'loginRequired': 'Please login first',
    'enrollmentOpen': 'Enrollment Open',
  };

  // ==================== Bengali Strings ====================
  static const Map<String, String> _bengaliStrings = {
    // General
    'app_name': 'মাহাদুল কিরাআত আল হিন্দ',
    'app_tagline': 'আধুনিক ইসলামিক শিক্ষা ও প্রতিষ্ঠান ব্যবস্থাপনা',
    'loading': 'লোড হচ্ছে...',
    'error': 'ত্রুটি',
    'retry': 'আবার চেষ্টা করুন',
    'cancel': 'বাতিল',
    'ok': 'ঠিক আছে',
    'yes': 'হ্যাঁ',
    'no': 'না',
    'save': 'সংরক্ষণ',
    'delete': 'মুছুন',
    'edit': 'সম্পাদনা',
    'submit': 'জমা দিন',
    'close': 'বন্ধ',
    'search': 'অনুসন্ধান',
    'filter': 'ফিল্টার',
    'sort': 'সাজান',
    'refresh': 'রিফ্রেশ',
    'viewAll': 'সব দেখুন',
    'seeMore': 'আরও দেখুন',
    'seeLess': 'কম দেখুন',
    'noData': 'কোনো তথ্য পাওয়া যায়নি',
    'somethingWentWrong': 'কিছু ভুল হয়েছে',

    // Navigation
    'nav_home': 'হোম',
    'nav_courses': 'কোর্স',
    'nav_audio': 'অডিও',
    'nav_more': 'আরও',

    // Auth
    'login': 'লগইন',
    'signup': 'নিবন্ধন',
    'logout': 'লগআউট',
    'email': 'ইমেইল',
    'password': 'পাসওয়ার্ড',
    'confirmPassword': 'পাসওয়ার্ড নিশ্চিত করুন',
    'forgotPassword': 'পাসওয়ার্ড ভুলে গেছেন?',
    'resetPassword': 'পাসওয়ার্ড রিসেট',
    'loginWithGoogle': 'গুগল দিয়ে লগইন',
    'orContinueWith': 'অথবা এর সাথে চালিয়ে যান',
    'dontHaveAccount': 'অ্যাকাউন্ট নেই?',
    'alreadyHaveAccount': 'ইতিমধ্যে অ্যাকাউন্ট আছে?',
    'createAccount': 'অ্যাকাউন্ত তৈরি করুন',
    'welcomeBack': 'স্বাগতম!',
    'loginSubtitle': 'শেখা চালিয়ে যেতে সাইন ইন করুন',
    'signupSubtitle': 'আপনার ইসলামিক শিক্ষার যাত্রা শুরু করুন',
    'rememberMe': 'মনে রাখুন',
    'otpVerification': 'ওটিপি যাচাই',
    'enterOtp': 'আপনার ইমেইলে পাঠানো ওটিপি লিখুন',
    'verify': 'যাচাই',
    'resendOtp': 'ওটিপি পুনরায় পাঠান',
    'newPassword': 'নতুন পাসওয়ার্ড',
    'passwordResetSuccess': 'পাসওয়ার্ড রিসেট সফল!',
    'loginSuccess': 'স্বাগতম!',
    'signupSuccess': 'অ্যাকাউন্ত সফলভাবে তৈরি হয়েছে!',
    'invalidCredentials': 'ভুল ইমেইল বা পাসওয়ার্ড',
    'emailRequired': 'ইমেইল প্রয়োজন',
    'passwordRequired': 'পাসওয়ার্ড প্রয়োজন',
    'invalidEmail': 'অবৈধ ইমেইল ঠিকানা',
    'passwordTooShort': 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে',
    'passwordsDoNotMatch': 'পাসওয়ার্ড মিলছে না',

    // Home
    'home': 'হোম',
    'featuredCourses': 'বিশেষ কোর্স',
    'shayekhSpotlight': 'শায়েখ পরিচিতি',
    'audioLibrary': 'অডিও লাইব্রেরি',
    'latestVideos': 'সর্বশেষ ভিডিও',
    'testimonials': 'প্রশংসাপত্র',
    'studentGallery': 'ছাত্র গ্যালারি',
    'announcements': 'ঘোষণা',
    'totalStudents': 'মোট ছাত্র',
    'totalCourses': 'মোট কোর্স',
    'totalShayekh': 'মোট শায়েখ',
    'coursesCompleted': 'কোর্স সম্পন্ন',

    // Courses
    'allCourses': 'সব কোর্স',
    'courseCategories': 'কোর্স বিভাগ',
    'enrollNow': 'এখনই ভর্তি হন',
    'enrolled': 'ভর্তি হয়েছে',
    'courseDetails': 'কোর্সের বিবরণ',
    'curriculum': 'পাঠ্যক্রম',
    'lessons': 'পাঠ',
    'students': 'ছাত্র',
    'rating': 'রেটিং',
    'reviews': 'রিভিউ',
    'relatedCourses': 'সম্পর্কিত কোর্স',
    'aboutCourse': 'কোর্স সম্পর্কে',
    'instructor': 'শিক্ষক',
    'duration': 'সময়কাল',
    'level': 'স্তর',
    'beginner': 'শুরুবর্তী',
    'intermediate': 'মাধ্যমিক',
    'advanced': 'উন্নত',
    'free': 'বিনামূল্যে',
    'paid': 'পেইড',
    'searchCourses': 'কোর্স অনুসন্ধান...',
    'noCoursesFound': 'কোনো কোর্স পাওয়া যায়নি',

    // Audio
    'audioLibraryTitle': 'অডিও লাইব্রেরি',
    'nowPlaying': 'এখন বাজছে',
    'playlists': 'প্লেলিস্ট',
    'favorites': 'পছন্দ',
    'recentlyPlayed': 'সম্প্রতি বাজানো',
    'downloads': 'ডাউনলোড',
    'sleepTimer': 'স্লিপ টাইমার',
    'playbackSpeed': 'প্লেব্যাক স্পিড',
    'addToFavorites': 'পছন্দে যোগ করুন',
    'removeFromFavorites': 'পছন্দ থেকে সরান',
    'queue': 'তালিকা',
    'noAudioFound': 'কোনো অডিও পাওয়া যায়নি',

    // Videos
    'videoLibrary': 'ভিডিও লাইব্রেরি',
    'watchNow': 'এখনই দেখুন',
    'continueWatching': 'দেখা চালিয়ে যান',
    'noVideosFound': 'কোনো ভিডিও পাওয়া যায়নি',

    // Attendance
    'attendance': 'উপস্থিতি',
    'monthlyReport': 'মাসিক রিপোর্ট',
    'attendancePercentage': 'উপস্থিতির শতাংশ',
    'present': 'উপস্থিত',
    'absent': 'অনুপস্থিত',
    'late': 'বিলম্বিত',
    'excused': 'অনুমোদিত',

    // Fees
    'feeManagement': 'ফি ব্যবস্থাপনা',
    'dueAmount': 'বকেয় পরিমাণ',
    'paymentHistory': 'পেমেন্ট ইতিহাস',
    'payNow': 'এখনই পরিশোধ করুন',
    'admissionFee': 'ভর্তি ফি',
    'monthlyFee': 'মাসিক ফি',
    'examFee': 'পরীক্ষার ফি',
    'hostelFee': 'হোস্টেল ফি',
    'libraryFee': 'লাইব্রেরি ফি',
    'totalPaid': 'মোট পরিশোধ',
    'totalDue': 'মোট বকেয়',

    // Certificates
    'myCertificates': 'আমার সার্টিফিকেট',
    'verifyCertificate': 'সার্টিফিকেট যাচাই',
    'certificateId': 'সার্টিফিকেট আইডি',
    'issuedOn': 'প্রদানের তারিখ',
    'noCertificates': 'এখনো কোনো সার্টিফিকেট পাওয়া যায়নি',
    'scanQR': 'QR কোড স্ক্যান করুন',
    'shareCertificate': 'সার্টিফিকেট শেয়ার',

    // Notifications
    'notifications': 'বিজ্ঞপ্তি',
    'markAllRead': 'সব পড়া হয়েছে বলে চিহ্নিত',
    'noNotifications': 'এখনো কোনো বিজ্ঞপ্তি নেই',

    // Profile
    'profile': 'প্রোফাইল',
    'editProfile': 'প্রোফাইল সম্পাদনা',
    'changePassword': 'পাসওয়ার্ড পরিবর্তন',
    'settings': 'সেটিংস',
    'language': 'ভাষা',
    'darkMode': 'ডার্ক মোড',
    'currentPassword': 'বর্তমান পাসওয়ার্ড',
    'newPasswordLabel': 'নতুন পাসওয়ার্ড',
    'account': 'অ্যাকাউন্ট',
    'privacy': 'গোপনীয়তা',
    'help': 'সাহায্য ও সমর্থন',
    'about': 'সম্পর্কে',
    'version': 'ভার্সন',
    'deleteAccount': 'অ্যাকাউন্ট মুছুন',
    'deleteAccountConfirm': 'আপনি কি নিশ্চিত আপনার অ্যাকাউন্ট মুছে ফেলতে চান? এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।',

    // Gallery
    'gallery': 'গ্যালারি',
    'photos': 'ছবি',
    'noGalleryItems': 'কোনো গ্যালারি আইটেম পাওয়া যায়নি',

    // Shayekh
    'shayekh': 'শায়েখ',
    'shayekhDetails': 'শায়েখের বিবরণ',
    'specialization': 'বিশেষত্ব',
    'country': 'দেশ',
    'coursesTaught': 'পাঠানো কোর্স',
    'follow': 'ফলো',
    'unfollow': 'আনফলো',

    // Onboarding
    'getStarted': 'শুরু করুন',
    'next': 'পরবর্তী',
    'skip': 'এড়িয়ে যান',
    'onboardingTitle1': 'কুরআন ও ইসলামিক অধ্যয়ন',
    'onboardingDesc1': 'বিশ্বের বিখ্যাত পণ্ডিতদের দ্বারা পাঠানো বিস্তৃত কোর্সে প্রবেশ।',
    'onboardingTitle2': 'আপনার অগ্রগতি ট্র্যাক করুন',
    'onboardingDesc2': 'বিস্তারিত অগ্রগতি বিশ্লেষণ এবং সার্টিফিকেট দিয়ে আপনার শেখার যাত্রা পর্যবেক্ষণ।',
    'onboardingTitle3': 'শুনুন ও দেখুন',
    'onboardingDesc3': 'প্রিমিয়াম মানের সাথে যেকোনো সময়, যেকোনো স্থানে তিলাওয়াত, বায়ান এবং লেকচার স্ট্রিম করুন।',

    // Dashboard
    'dashboard': 'ড্যাশবোর্ড',
    'overview': 'সারসংক্ষেপ',
    'manageStudents': 'ছাত্র পরিচালনা',
    'manageCourses': 'কোর্স পরিচালনা',
    'manageAttendance': 'উপস্থিতি পরিচালনা',
    'manageFees': 'ফি পরিচালনা',
    'reports': 'রিপোর্ট',

    // AI Assistant
    'aiAssistant': 'এআই সহকারী',
    'askAnything': 'প্রতিষ্ঠান সম্পর্কে যেকোনো কিছু জিজ্ঞাসা করুন...',
    'aiNotAvailable': 'এআই সহকারী শীঘ্রই আসছে!',

    // Extra
    'myCourses': 'আমার কোর্স',
    'batch': 'ব্যাচ',
    'loginRequired': 'প্রথমে লগইন করুন',
    'enrollmentOpen': 'ভর্তি চলছে',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'bn'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
