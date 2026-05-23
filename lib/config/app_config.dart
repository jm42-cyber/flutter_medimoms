import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api';
  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  static String get appName => dotenv.env['APP_NAME'] ?? 'MediMoms';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
  
  static bool get enableDebugLogs => dotenv.env['ENABLE_DEBUG_LOGS']?.toLowerCase() == 'true';
  static bool get enableBiometric => dotenv.env['ENABLE_BIOMETRIC']?.toLowerCase() == 'true';
  static bool get enableOfflineMode => dotenv.env['ENABLE_OFFLINE_MODE']?.toLowerCase() == 'true';

  static bool get isProduction => appEnv == 'production';
  static bool get isDevelopment => appEnv == 'development';

  static Future<void> initialize() async {
    try {
      if (kReleaseMode) {
        await dotenv.load(fileName: 'assets/.env.production');
      } else {
        await dotenv.load(fileName: 'assets/.env.development');
      }
      
      if (enableDebugLogs) {
        debugPrint('✅ AppConfig initialized');
        debugPrint('   Environment: $appEnv');
        debugPrint('   API URL: $apiUrl');
      }
    } catch (e) {
      debugPrint('❌ Error loading environment: $e');
      await dotenv.load(fileName: 'assets/.env');
    }
  }

  static void logConfig() {
    if (!enableDebugLogs) return;
    
    debugPrint('=== App Configuration ===');
    debugPrint('App Name: $appName');
    debugPrint('Version: $appVersion');
    debugPrint('Environment: $appEnv');
    debugPrint('API URL: $apiUrl');
    debugPrint('API Timeout: ${apiTimeout}ms');
    debugPrint('========================');
  }
}
