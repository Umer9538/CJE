/// CJE Platform Route Names
/// All route paths defined as constants
class RouteNames {
  RouteNames._();

  // ============================================
  // INITIAL ROUTES
  // ============================================

  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // ============================================
  // AUTH ROUTES
  // ============================================

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String profileSetup = '/profile-setup';
  static const String pendingApproval = '/pending-approval';
  static const String suspended = '/suspended';

  // ============================================
  // MAIN APP ROUTES
  // ============================================

  static const String home = '/home';
  static const String announcements = '/announcements';
  static const String announcementDetail = '/announcements/:id';
  static const String createAnnouncement = '/announcements/create';

  static const String meetings = '/meetings';
  static const String meetingDetail = '/meetings/:id';
  static const String createMeeting = '/meetings/create';

  static const String initiatives = '/initiatives';
  static const String initiativeDetail = '/initiatives/:id';
  static const String createInitiative = '/initiatives/create';

  static const String documents = '/documents';
  static const String documentDetail = '/documents/:id';
  static const String uploadDocument = '/documents/upload';

  static const String polls = '/polls';
  static const String pollDetail = '/polls/:id';
  static const String createPoll = '/polls/create';

  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';

  // ============================================
  // ADMIN ROUTES
  // ============================================

  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminSetup = '/admin-setup';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminSchools = '/admin/schools';
  static const String adminSchoolDetail = '/admin/schools/:id';
  static const String adminGds = '/admin/gds';
  static const String adminGdsDetail = '/admin/gds/:id';

  // ============================================
  // GLOBAL ROUTES
  // ============================================

  static const String calendar = '/calendar';
  static const String search = '/search';
  static const String notifications = '/notifications';

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get announcement detail route with ID
  static String announcementDetailPath(String id) => '/announcements/$id';

  /// Get meeting detail route with ID
  static String meetingDetailPath(String id) => '/meetings/$id';

  /// Get initiative detail route with ID
  static String initiativeDetailPath(String id) => '/initiatives/$id';

  /// Get document detail route with ID
  static String documentDetailPath(String id) => '/documents/$id';

  /// Get poll detail route with ID
  static String pollDetailPath(String id) => '/polls/$id';

  /// Get user detail route with ID (admin)
  static String adminUserDetailPath(String id) => '/admin/users/$id';

  /// Get school detail route with ID (admin)
  static String adminSchoolDetailPath(String id) => '/admin/schools/$id';

  /// Get GDS detail route with ID (admin)
  static String adminGdsDetailPath(String id) => '/admin/gds/$id';
}
