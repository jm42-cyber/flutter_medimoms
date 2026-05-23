# Flutter MediMoms - Setup & Integration Guide

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Current State](#current-state)
3. [Backend Integration](#backend-integration)
4. [Environment Setup](#environment-setup)
5. [API Integration](#api-integration)
6. [Step-by-Step Setup](#step-by-step-setup)
7. [Testing](#testing)
8. [Deployment](#deployment)

---

## 📊 Project Overview

### What is Flutter MediMoms?

Flutter MediMoms is the **mobile companion app** for the MediMoms 2.0 web system. It allows midwives to manage health records on-the-go using their smartphones or tablets.

### Architecture

```
┌─────────────────────┐
│  Flutter Mobile App │
│   (This Project)    │
└──────────┬──────────┘
           │ HTTP/HTTPS
           │ JWT Token Auth
           ↓
┌─────────────────────┐
│   Laravel Backend   │
│ (basta_midwives2.0) │
└──────────┬──────────┘
           │ MySQL
           ↓
┌─────────────────────┐
│  MySQL Database     │
│    (medimoms)       │
└─────────────────────┘
```

### Key Points
- ✅ Flutter app connects to Laravel API (NOT directly to database)
- ✅ Same database as web app (shared data)
- ✅ JWT token authentication
- ✅ Real-time data synchronization
- ✅ Offline caching support

---

## 🔍 Current State

### ✅ What's Already Built

1. **Complete UI/UX**
   - All screens designed and implemented
   - Modern Material Design 3
   - Consistent green theme (#10B981)
   - Responsive layouts

2. **Navigation System**
   - App drawer with all modules
   - Route management
   - Deep linking support

3. **State Management**
   - Provider pattern implemented
   - AuthProvider, PatientProvider, etc.
   - Theme management

4. **Screen Components**
   - Login/Register screens
   - Dashboard (Admin & Midwife)
   - Immunization Records
   - Maternal Care Records
   - Family Planning Records
   - Senior Citizen Records
   - Settings & Profile

### ❌ What Needs Integration

1. **API Connection**
   - Currently using mock data
   - Need to connect to Laravel backend

2. **Real Authentication**
   - Mock login needs to be replaced
   - JWT token management

3. **Data Persistence**
   - Local storage for offline support
   - Secure token storage

4. **Error Handling**
   - Network errors
   - API errors
   - Validation errors

---

## 🔗 Backend Integration

### Laravel Backend (basta_midwives2.0)

Your existing Laravel backend already has:

✅ **API Routes** (`backend/routes/api.php`)
```php
// Authentication
POST   /api/register
POST   /api/login
POST   /api/logout
GET    /api/me

// Users
GET    /api/users
POST   /api/users
PUT    /api/users/{id}

// Barangays
GET    /api/barangays

// Immunization Records
GET    /api/immunization-records
POST   /api/immunization-records
PUT    /api/immunization-records/{id}
DELETE /api/immunization-records/{id}

// Similar endpoints for:
// - family-planning-records
// - maternal-care-records
// - senior-citizen-records
```

✅ **Authentication** (Laravel Sanctum)
- Token-based authentication
- Secure API access
- Role-based permissions

✅ **Database Connection**
- Connected to `medimoms` database
- All tables and relationships set up
- Migrations and seeders ready

### What Flutter Needs to Do

1. **Send HTTP requests** to Laravel API
2. **Store JWT token** securely
3. **Include token** in all API requests
4. **Handle responses** and errors
5. **Cache data** for offline use

---

## 🔧 Environment Setup

### Does Flutter Use .env Files?

**YES!** But differently than Node.js/PHP.

### Option 1: flutter_dotenv (Recommended)

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - assets/.env
```

```env
# assets/.env
API_URL=http://localhost:8000/api
APP_NAME=MediMoms
APP_VERSION=1.0.0
```

```dart
// Usage in code
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();
String apiUrl = dotenv.env['API_URL']!;
```

### Option 2: Config Class (Also Recommended)

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String apiUrl = kDebugMode
    ? 'http://localhost:8000/api'      // Development
    : 'https://api.medimoms.com/api';  // Production
    
  static const int apiTimeout = 30000;
  static const String appName = 'MediMoms';
}
```

### What Goes in Flutter .env?

✅ **Include:**
- API_URL
- APP_NAME
- APP_VERSION
- Feature flags

❌ **NEVER Include:**
- Database credentials (DB_HOST, DB_PASSWORD)
- Email passwords (MAIL_PASSWORD)
- Backend secret keys (APP_KEY)
- Any sensitive backend configuration

**Why?** Mobile apps can be decompiled. Anyone can extract your .env file.

---

## 📦 Required Packages

Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # HTTP & API
  dio: ^5.4.0                   # HTTP client (better than http package)
  
  # Environment Variables
  flutter_dotenv: ^5.1.0        # .env file support
  
  # Local Storage
  shared_preferences: ^2.2.2    # Simple key-value storage
  flutter_secure_storage: ^9.0.0 # Secure token storage
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
  # Date & Time
  intl: ^0.19.0                 # Date formatting
  
  # UI Components
  cupertino_icons: ^1.0.2       # iOS icons
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  build_runner: ^2.4.8          # Code generation
  json_serializable: ^6.7.1     # JSON model generation
```

---

## 🔐 Authentication Flow

### Current (Mock)

```dart
// providers/auth_provider.dart
Future<bool> login(String username, String password) async {
  // Mock user check
  if (!_mockUsers.containsKey(username)) {
    return false;
  }
  // Set user data
  _userId = _mockUsers[username]!['id'];
  _userName = _mockUsers[username]!['name'];
  return true;
}
```

### Updated (Real API)

```dart
// services/auth_service.dart
class AuthService {
  final ApiService _apiService;
  final StorageService _storage;
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _apiService.post('/auth/login', {
      'username': username,
      'password': password,
    });
    
    // Store token securely
    await _storage.saveToken(response['token']);
    
    return response['user'];
  }
}

// providers/auth_provider.dart
Future<bool> login(String username, String password) async {
  try {
    final user = await _authService.login(username, password);
    _userId = user['id'].toString();
    _userName = user['name'];
    _userRole = user['role'];
    notifyListeners();
    return true;
  } catch (e) {
    return false;
  }
}
```

---

## 📡 API Integration

### API Service Structure

```dart
// lib/services/api_service.dart
class ApiService {
  final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add interceptors for token and error handling
    _dio.interceptors.add(AuthInterceptor());
  }
  
  Future<dynamic> get(String path) async {
    final response = await _dio.get(path);
    return response.data;
  }
  
  Future<dynamic> post(String path, dynamic data) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }
  
  // PUT, DELETE methods...
}
```

### Token Management

```dart
// lib/services/storage_service.dart
class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }
  
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
  
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }
}
```

### Auth Interceptor

```dart
// lib/services/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  final StorageService _storage;
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired - logout user
      // Navigate to login screen
    }
    handler.next(err);
  }
}
```

---

## 🚀 Step-by-Step Setup

### Phase 1: Install Packages

1. **Update pubspec.yaml**
```bash
flutter pub get
```

2. **Verify installation**
```bash
flutter pub deps
```

### Phase 2: Create Configuration Files

1. **Create assets/.env**
```env
API_URL=http://localhost:8000/api
APP_NAME=MediMoms
APP_VERSION=1.0.0
```

2. **Create lib/config/app_config.dart**
```dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiUrl = kDebugMode
    ? 'http://localhost:8000/api'
    : 'https://api.medimoms.com/api';
    
  static const int apiTimeout = 30000;
  static const String appName = 'MediMoms';
  static const String appVersion = '1.0.0';
}
```

3. **Create lib/config/api_endpoints.dart**
```dart
class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  
  // Immunization
  static const String immunizationRecords = '/immunization-records';
  
  // Maternal Care
  static const String maternalCareRecords = '/maternal-care-records';
  
  // Family Planning
  static const String familyPlanningRecords = '/family-planning-records';
  
  // Senior Citizen
  static const String seniorCitizenRecords = '/senior-citizen-records';
  
  // Barangays
  static const String barangays = '/barangays';
}
```

### Phase 3: Create Service Layer

1. **Create lib/services/api_service.dart**
2. **Create lib/services/storage_service.dart**
3. **Create lib/services/auth_service.dart**
4. **Create lib/services/patient_service.dart**

### Phase 4: Create Data Models

1. **Create lib/models/user.dart**
2. **Create lib/models/patient.dart**
3. **Create lib/models/immunization_record.dart**
4. **Create lib/models/maternal_care_record.dart**

### Phase 5: Update Providers

1. **Update lib/providers/auth_provider.dart**
2. **Update lib/providers/patient_provider.dart**

### Phase 6: Test Integration

1. **Start Laravel backend**
```bash
cd basta_midwives2.0/backend
php artisan serve
```

2. **Run Flutter app**
```bash
flutter run
```

3. **Test login** with credentials from database

---

## 🧪 Testing

### Unit Tests

```dart
// test/services/api_service_test.dart
void main() {
  group('ApiService', () {
    test('should login successfully', () async {
      final apiService = ApiService();
      final response = await apiService.post('/auth/login', {
        'username': 'admin',
        'password': 'admin123',
      });
      expect(response['token'], isNotNull);
    });
  });
}
```

### Integration Tests

```bash
flutter test integration_test/
```

### Run All Tests

```bash
flutter test
```

---

## 📱 Deployment

### Android

1. **Update version in pubspec.yaml**
```yaml
version: 1.0.0+1
```

2. **Build APK**
```bash
flutter build apk --release
```

3. **Build App Bundle (for Play Store)**
```bash
flutter build appbundle --release
```

### iOS

1. **Update version in pubspec.yaml**

2. **Build**
```bash
flutter build ios --release
```

3. **Open Xcode and archive**

---

## 🔍 Troubleshooting

### Common Issues

**1. API Connection Failed**
```
Solution:
- Check if Laravel backend is running
- Verify API_URL in .env
- Check network connectivity
- Disable VPN if using localhost
```

**2. CORS Error**
```
Solution:
- Update backend config/cors.php
- Add mobile app origin
- Restart Laravel server
```

**3. Token Expired**
```
Solution:
- App will auto-logout
- User needs to login again
- Check token expiration in backend
```

**4. Build Errors**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dio Package](https://pub.dev/packages/dio)
- [Provider Package](https://pub.dev/packages/provider)
- [Laravel Sanctum](https://laravel.com/docs/sanctum)

---

## ✅ Checklist

Before deploying:

- [ ] All packages installed
- [ ] .env file configured
- [ ] API service implemented
- [ ] Authentication working
- [ ] CRUD operations tested
- [ ] Error handling implemented
- [ ] Offline caching working
- [ ] UI/UX polished
- [ ] Tests passing
- [ ] Build successful

---

**Ready to integrate? Follow the steps above one by one!** 🚀
