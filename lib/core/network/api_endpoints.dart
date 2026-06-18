abstract class ApiEndpoints {
  static const String baseUrl = 'https://mahad-al-hind.vercel.app';
  
  // Auth
  static const String login = '/api/user/login';
  static const String signup = '/api/user/signup';
  static const String googleLogin = '/api/user/googleLogin';
  static const String forgetPassword = '/api/user/forgetPassword';
  static const String resetPassword = '/api/user/resetPassword';
  
  // V1 Auth
  static const String v1GoogleAuth = '/api/v1/auth/google';
  static const String v1RefreshToken = '/api/v1/auth/refresh';
  static const String v1Logout = '/api/v1/auth/logout';
  static const String v1Me = '/api/v1/auth/me';
  
  // User
  static const String allUsers = '/api/user/allUsers';
  static const String allUsersCount = '/api/user/allUsersCount';
  static String singleUser(String id) => '/api/user/singleUser/$id';
  static const String updateUser = '/api/user/updateUser/';
  static const String changePassword = '/api/user/changePassword';
  static const String deleteMyAccount = '/api/user/deleteMyAccount';
  static String deleteUser(String id) => '/api/user/deleteUser/$id';
  static String makeAdmin(String id) => '/api/user/makeAdmin/$id';
  static String undoAdmin(String id) => '/api/user/undoAdmin/$id';
  static String changeRole(String id) => '/api/user/changeRole/$id';
  
  // Courses
  static const String topCourses = '/api/course/topCourses';
  static const String getAllCourses = '/api/course/getAllCourses';
  static const String createCourse = '/api/course/createCourse';
  static String singleCourse(String id) => '/api/course/getSingleCourse/$id';
  static const String relatedCourses = '/api/course/getReletedCourse';
  static const String courseCategories = '/api/course/getCourseCategories';
  static const String courseCount = '/api/course/getCourseCount';
  
  // Enrollment
  static const String paymentOrder = '/api/course/payment/order';
  static const String manualEnroll = '/api/course/manual-enroll';
  static const String allEnrollments = '/api/course/all-enrollments';
  static const String pendingEnrollments = '/api/course/pending-enrollments';
  static String approveEnrollment(String id) => '/api/course/approve-enrollment/$id';
  static String rejectEnrollment(String id) => '/api/course/reject-enrollment/$id';
  static String enrolledCourses(String userId) => '/api/course/getAllEnrolledCourse/$userId';
  static const String enrolledUsersCount = '/api/course/enrolledUsersCourses';
  static const String totalRevenue = '/api/course/getTotalRevenue';
  static const String totalPayment = '/api/course/getTotalPayment';
  static String courseProgress(String studentId) => '/api/course/getUserCourseProgress/$studentId';
  static String spentByStudent(String studentId) => '/api/course/getSpentByStudent/$studentId';
  static String videosCount(String studentId) => '/api/course/getVideosCount/$studentId';
  
  // Course Actions
  static String unlockVideo(String studentId) => '/api/course/unlockVideo/$studentId';
  static String completeQuiz(String studentId) => '/api/course/completeQuiz/$studentId';
  static String completeCourse(String studentId) => '/api/course/completeCourse/$studentId';
  
  // Reviews
  static const String reviews = '/api/review';
  static String giveRating(String id) => '/api/course/giveRating/$id';
  
  // Videos
  static const String videos = '/api/videos';
  
  // Gallery
  static const String gallery = '/api/gallery';
  static const String galleryUpload = '/api/gallery/upload';
  static String galleryItem(String id) => '/api/gallery/$id';
  
  // Media
  static const String mediaPublic = '/api/media/public';
  static const String mediaAdmin = '/api/media/admin';
  static const String mediaUpload = '/api/media/upload';
  
  // Site
  static const String siteContent = '/api/site-content/public';
  static const String siteSettings = '/api/site-settings/home-page';
  static const String updateSiteSettings = '/api/site-settings/home-page';
  static const String updateSiteContent = '/api/site-content/admin';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String unreadCount = '/api/notifications/unread-count';
  static String readNotification(String id) => '/api/notifications/read/$id';
  static const String readAllNotifications = '/api/notifications/read-all';
  static const String adminNotifications = '/api/notifications';
  static String singleNotification(String id) => '/api/notifications/$id';
  
  // Certificates
  static String verifyCertificate(String id) => '/api/certificate/check/$id';
  static const String certificates = '/api/certificate';
  
  // Orders
  static const String orders = '/api/orders';
  
  // App Update
  static const String appVersion = '/api/app/version';
  static const String adminAppUpdate = '/api/admin/app-update';
}
