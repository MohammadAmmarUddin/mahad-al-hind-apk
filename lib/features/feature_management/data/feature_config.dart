class FeatureConfig {
  static const Map<String, String> featureDescriptions = {
    'courses': 'Course browsing and enrollment',
    'audioLibrary': 'Audio streaming and playback',
    'videoLibrary': 'Video streaming platform',
    'attendance': 'Student attendance tracking',
    'feeManagement': 'Fee collection and management',
    'gallery': 'Photo and media gallery',
    'certificates': 'Certificate issuance and verification',
    'aiAssistant': 'AI-powered assistant',
    'notifications': 'Push notifications',
    'reviews': 'Course reviews and ratings',
    'shayekh': 'Shayekh profiles and content',
    'studentManagement': 'Student administration',
    'enrollment': 'Course enrollment system',
    'dashboard': 'Admin dashboard',
    'liveClasses': 'Live class streaming',
    'offlineMode': 'Offline content access',
  };

  static bool shouldShowFeature(Map<String, dynamic> featureFlags, String feature) {
    return featureFlags[feature] == true;
  }
}
