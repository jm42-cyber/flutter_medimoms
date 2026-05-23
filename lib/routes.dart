import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboards/midwife_dashboard.dart';
import 'screens/dashboards/admin_dashboard.dart';
import 'screens/modules/placeholder_screens.dart';
import 'screens/modules/maternal_care_screen.dart';
import 'screens/modules/senior_citizen_screen.dart';
import 'screens/modules/family_planning_screen.dart';
import 'screens/modules/immunization_screen.dart';
import 'screens/features/appointments_screen.dart';
import 'screens/features/archives_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/profile_screen.dart';
import 'screens/features/all_patients_screen.dart';
import 'screens/features/help_support_screen.dart';
import 'screens/features/alerts_screen.dart';
import 'screens/features/admin_alerts_screen.dart';
import 'screens/modules/patients_screen.dart';
import 'screens/admin/manage_midwives_screen.dart';
import 'screens/admin/pending_accounts_screen.dart';
import 'screens/admin/manage_barangays_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/audit_logs_screen.dart';
import 'screens/admin/admin_settings_screen.dart';

class Routes {
  // Route names as constants
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String midwifeDashboard = '/midwife-dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String maternalCare = '/maternal-care';
  static const String seniorCitizen = '/senior-citizen';
  static const String familyPlanning = '/family-planning';
  static const String immunization = '/immunization';
  static const String archivedPatients = '/archived-patients';
  // aiPrompt removed per user request
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String reports = '/reports';
  static const String alerts = '/alerts';
  static const String adminAlerts = '/admin/alerts';
  static const String manageMidwives = '/admin/manage-midwives';
  static const String pendingAccounts = '/admin/pending-accounts';
  static const String manageBarangays = '/admin/manage-barangays';
  static const String reportsPage = '/admin/reports';
  static const String auditLogs = '/admin/audit-logs';
  static const String adminSettings = '/admin/settings';
  static const String helpSupport = '/help-support';
  static const String patients = '/patients';

  // Generate route method
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );

      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );

      case midwifeDashboard:
        return MaterialPageRoute(
          builder: (_) => const MidwifeDashboard(),
          settings: settings,
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
          settings: settings,
        );

      case maternalCare:
        return MaterialPageRoute(
          builder: (_) => const MaternalCareScreen(),
          settings: settings,
        );

      case seniorCitizen:
        return MaterialPageRoute(
          builder: (_) => const SeniorCitizenScreen(),
          settings: settings,
        );

      case familyPlanning:
        return MaterialPageRoute(
          builder: (_) => const FamilyPlanningScreen(),
          settings: settings,
        );

      case immunization:
        return MaterialPageRoute(
          builder: (_) => const ImmunizationScreen(),
          settings: settings,
        );

      case archivedPatients:
        return MaterialPageRoute(
          builder: (_) => const ArchivesScreen(),
          settings: settings,
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case calendar:
        return MaterialPageRoute(
          builder: (_) => const AppointmentsScreen(),
          settings: settings,
        );

      case reports:
        return MaterialPageRoute(
          builder: (_) => const AllPatientsScreen(),
          settings: settings,
        );

      case alerts:
        return MaterialPageRoute(
          builder: (_) => const AlertsScreen(),
          settings: settings,
        );

      case adminAlerts:
        return MaterialPageRoute(
          builder: (_) => const AdminAlertsScreen(),
          settings: settings,
        );

      case helpSupport:
        return MaterialPageRoute(
          builder: (_) => const HelpSupportScreen(),
          settings: settings,
        );

      case patients:
        return MaterialPageRoute(
          builder: (_) => const PatientsScreen(),
          settings: settings,
        );

      case manageMidwives:
        return MaterialPageRoute(
          builder: (_) => const ManageMidwivesScreen(),
          settings: settings,
        );

      case pendingAccounts:
        return MaterialPageRoute(
          builder: (_) => const PendingAccountsScreen(),
          settings: settings,
        );

      case manageBarangays:
        return MaterialPageRoute(
          builder: (_) => const ManageBarangaysScreen(),
          settings: settings,
        );

      case reportsPage:
        return MaterialPageRoute(
          builder: (_) => const ReportsScreen(),
          settings: settings,
        );

      case auditLogs:
        return MaterialPageRoute(
          builder: (_) => const AuditLogsScreen(),
          settings: settings,
        );

      case adminSettings:
        return MaterialPageRoute(
          builder: (_) => const AdminSettingsScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 100,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Route Not Found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No route defined for: ${settings.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, login),
                    icon: const Icon(Icons.home),
                    label: const Text('Go to Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  // (removed helper) Specific routes now point to implemented screens.
}
