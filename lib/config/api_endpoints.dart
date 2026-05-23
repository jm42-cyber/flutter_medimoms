class ApiEndpoints {
  ApiEndpoints._();

  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyOtp = '/verify-otp';
  static const String resendOtp = '/resend-otp';

  // User endpoints
  static const String users = '/users';
  static String user(int id) => '/users/$id';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';

  // Patient endpoints
  static const String patients = '/patients';
  static String patient(int id) => '/patients/$id';
  static String patientArchive(int id) => '/patients/$id/archive';
  static String patientRestore(int id) => '/patients/$id/restore';
  static const String archivedPatients = '/patients/archived';

  // Appointment endpoints
  static const String appointments = '/appointments';
  static String appointment(int id) => '/appointments/$id';
  static String appointmentCancel(int id) => '/appointments/$id/cancel';
  static String appointmentComplete(int id) => '/appointments/$id/complete';

  // Immunization endpoints
  static const String immunizations = '/immunization-records';
  static String immunization(int id) => '/immunization-records/$id';
  static String patientImmunizations(int patientId) => '/patients/$patientId/immunizations';

  // Maternal Care endpoints
  static const String maternalRecords = '/maternal-records';
  static String maternalRecord(int id) => '/maternal-records/$id';
  static String patientMaternalRecords(int patientId) => '/patients/$patientId/maternal-records';

  // Family Planning endpoints
  static const String familyPlanningRecords = '/family-planning-records';
  static String familyPlanningRecord(int id) => '/family-planning-records/$id';
  static String patientFamilyPlanningRecords(int patientId) => '/patients/$patientId/family-planning';

  // Senior Citizen endpoints
  static const String seniorCitizenRecords = '/senior-citizen-records';
  static String seniorCitizenRecord(int id) => '/senior-citizen-records/$id';
  static String patientSeniorRecords(int patientId) => '/patients/$patientId/senior-records';

  // Child Care endpoints
  static const String childCareRecords = '/child-care-records';
  static String childCareRecord(int id) => '/child-care-records/$id';
  static String patientChildCareRecords(int patientId) => '/patients/$patientId/child-care';

  // Reports endpoints
  static const String reports = '/reports';
  static const String reportsSummary = '/reports/summary';
  static const String reportsImmunization = '/reports/immunization';
  static const String reportsMaternalCare = '/reports/maternal-care';
  static const String reportsFamilyPlanning = '/reports/family-planning';

  // Dashboard endpoints
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardRecentActivities = '/dashboard/recent-activities';
}
