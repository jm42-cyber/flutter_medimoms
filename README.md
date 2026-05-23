# MediMoms Mobile - Flutter Application

A comprehensive mobile health management system for midwives and healthcare professionals to manage maternal care, immunization, family planning, and senior citizen health services.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Dart](https://img.shields.io/badge/Dart-2.19+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🌟 Features

### ✅ Fully Implemented Modules

#### 🔐 Authentication System
- Secure login with JWT token authentication
- Session management with automatic timeout
- Password change functionality
- Role-based access control (Admin, Midwife)
- Secure token storage

#### 📊 Dashboard
- Real-time statistics and overview
- Today's appointments
- Recent activity feed
- Quick actions menu
- Notifications system
- Assigned barangays display

#### 💉 Immunization Records Module
- Child immunization tracking
- Complete vaccine schedule (BCG, Hepa B, Pentavalent, OPV, IPV, PCV, MMR, Rotavirus)
- Birth information management
- Parent details tracking
- Search and filter functionality
- Archive/restore records
- Pagination support (15 records per page)

#### 🤰 Maternal Care Module
- Pregnancy tracking with risk assessment
- Prenatal visit monitoring
- Vital signs tracking (BP, weight, fundal height, FHR)
- LMP and EDD calculation
- Gravida, parity, and abortion history
- TT immunization tracking
- Delivery planning
- High-risk patient alerts
- Pagination support

#### 👨👩👧👦 Family Planning Module
- Client registration and management
- Contraceptive method tracking
- Service status monitoring
- Medical history recording
- Visit scheduling
- Method effectiveness tracking
- Pagination support

#### 👴 Senior Citizen Care Module
- Elderly patient management
- Chronic condition tracking
- Medication management
- Health screening records
- Vital signs monitoring (BP, blood sugar, BMI)
- Checkup scheduling
- Emergency contact management
- Pagination support

#### ⚙️ Settings & Profile
- User profile management
- Notification preferences
- Theme toggle (Dark/Light mode)
- Language settings
- Password change
- App information

#### 📋 Additional Features
- All patients view across programs
- Advanced search and filtering
- Calendar integration
- Reports and analytics
- Help & support
- Offline data caching
- Pull-to-refresh

## 🏗️ Architecture

### Backend Integration
```
Flutter App (Mobile)
    ↓ HTTP/HTTPS (JWT Token)
Laravel Backend API (basta_midwives2.0)
    ↓ MySQL Connection
MySQL Database (medimoms)
```

### Tech Stack
- **Frontend:** Flutter 3.0+ with Dart
- **State Management:** Provider pattern
- **HTTP Client:** Dio for API calls
- **Local Storage:** SharedPreferences + FlutterSecureStorage
- **Backend:** Laravel 10 API
- **Database:** MySQL (shared with web app)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 2.19 or higher
- Android Studio / VS Code with Flutter extensions
- Git
- **Backend:** basta_midwives2.0 Laravel API running

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/flutter_medimoms.git
cd flutter_medimoms
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment**

Create `assets/.env` file:
```env
API_URL=http://localhost:8000/api
APP_NAME=MediMoms
APP_VERSION=1.0.0
```

Update `pubspec.yaml` to include the .env file:
```yaml
flutter:
  assets:
    - assets/.env
```

4. **Run the application**
```bash
flutter run
```

### Backend Setup

Make sure your Laravel backend is running:
```bash
cd basta_midwives2.0/backend
php artisan serve
```

Backend should be accessible at: `http://localhost:8000`

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── routes.dart                        # Navigation routes
├── config/
│   ├── app_config.dart               # Environment configuration
│   └── api_endpoints.dart            # API route constants
├── models/
│   ├── user.dart                     # User model
│   ├── patient.dart                  # Patient model
│   └── appointment.dart              # Appointment model
├── services/
│   ├── api_service.dart              # HTTP client wrapper
│   ├── auth_service.dart             # Authentication API
│   ├── patient_service.dart          # Patient API calls
│   └── storage_service.dart          # Local storage
├── providers/
│   ├── auth_provider.dart            # Authentication state
│   ├── patient_provider.dart         # Patient data state
│   ├── appointment_provider.dart     # Appointment state
│   ├── otp_provider.dart             # OTP state
│   └── theme_provider.dart           # Theme state
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         # Login interface
│   │   └── register_screen.dart      # Registration
│   ├── dashboards/
│   │   ├── admin_dashboard.dart      # Admin dashboard
│   │   └── midwife_dashboard.dart    # Midwife dashboard
│   ├── modules/
│   │   ├── immunization_screen.dart  # Immunization records
│   │   ├── maternal_care_screen.dart # Maternal care
│   │   ├── family_planning_screen.dart # Family planning
│   │   ├── senior_citizen_screen.dart # Senior care
│   │   └── patients_screen.dart      # All patients
│   ├── features/
│   │   ├── calendar_screen.dart      # Calendar view
│   │   ├── reports_screen.dart       # Reports
│   │   ├── appointments_screen.dart  # Appointments
│   │   └── help_support_screen.dart  # Help
│   └── settings/
│       ├── settings_screen.dart      # Settings
│       └── profile_screen.dart       # User profile
└── widgets/
    ├── app_drawer.dart               # Navigation drawer
    └── dashboard_layout.dart         # Dashboard wrapper
```

## 🔑 Login Credentials

Use these credentials to test (must match backend database):

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | `admin123` |
| Midwife | `midwife1` | `midwife123` |

## 🎨 Design System

### Color Palette

- **Primary (Green)**: `#10B981` - Main actions, success states
- **Blue**: `#3B82F6` - Informational, senior care
- **Orange**: `#F59E0B` - Warnings, child care
- **Purple**: `#8B5CF6` - Family planning
- **Pink**: `#EC4899` - Maternal care
- **Red**: `#EF4444` - Critical, errors, danger

### Typography

- **Display**: Bold, 24-32px
- **Headings**: Semi-bold, 18-20px
- **Body**: Regular, 14-16px
- **Caption**: Regular, 12-13px

## 📦 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1              # State management
  dio: ^5.4.0                   # HTTP client
  flutter_dotenv: ^5.1.0        # Environment variables
  shared_preferences: ^2.2.2    # Local storage
  flutter_secure_storage: ^9.0.0 # Secure token storage
  intl: ^0.19.0                 # Date formatting
  json_annotation: ^4.8.1       # JSON serialization
  cupertino_icons: ^1.0.2       # iOS icons

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
```

## 🔧 Configuration

### API Configuration

Edit `lib/config/app_config.dart`:
```dart
class AppConfig {
  static const String apiUrl = kDebugMode
    ? 'http://localhost:8000/api'      // Development
    : 'https://api.medimoms.com/api';  // Production
    
  static const int apiTimeout = 30000;
  static const String appName = 'MediMoms';
}
```

### Adding New API Endpoints

Edit `lib/config/api_endpoints.dart`:
```dart
class ApiEndpoints {
  static const String login = '/auth/login';
  static const String patients = '/patients';
  // Add more endpoints...
}
```

## 🎯 Key Features Implementation

### Authentication Flow
1. User enters credentials
2. App sends POST request to `/api/auth/login`
3. Backend validates and returns JWT token
4. Token stored securely in FlutterSecureStorage
5. Token included in all subsequent API requests
6. Auto-logout on token expiration

### Data Synchronization
- Real-time data from Laravel backend
- Pagination for large datasets (15 records per page)
- Pull-to-refresh for manual sync
- Offline caching for viewed records
- Automatic retry on network failure

### Search & Filter
- Global search across all modules
- Filter by status, barangay, date range
- Real-time search results
- Debounced search input

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/services/api_service_test.dart
```

## 🚀 Building for Production

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```
Then open Xcode and archive for App Store.

### Web (Optional)
```bash
flutter build web --release
```
Output: `build/web/`

## 📝 API Integration Guide

### Making API Calls

```dart
// Using ApiService
final apiService = ApiService();

// GET request
final response = await apiService.get('/patients');

// POST request
final response = await apiService.post('/patients', {
  'name': 'John Doe',
  'age': 30,
});

// PUT request
final response = await apiService.put('/patients/1', {
  'name': 'Jane Doe',
});

// DELETE request
await apiService.delete('/patients/1');
```

### Error Handling

```dart
try {
  final response = await apiService.get('/patients');
  // Handle success
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Unauthorized - logout user
  } else if (e.response?.statusCode == 404) {
    // Not found
  } else {
    // Other errors
  }
}
```

## 🛠️ Development Tips

### Hot Reload
Press `r` in terminal for hot reload during development.

### Debug Mode
```bash
flutter run --debug
```

### Release Mode
```bash
flutter run --release
```

### Clear Cache
```bash
flutter clean
flutter pub get
```

## 🐛 Troubleshooting

### Common Issues

**1. API Connection Failed**
- Ensure Laravel backend is running
- Check API_URL in .env file
- Verify network connectivity
- Check CORS settings in Laravel

**2. Token Expired**
- App will auto-logout
- User needs to login again
- Check token expiration time in backend

**3. Build Errors**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

**4. iOS Build Issues**
```bash
cd ios
pod install
cd ..
flutter run
```

## 📱 Supported Platforms

- ✅ Android 5.0+ (API 21+)
- ✅ iOS 11.0+
- ⚠️ Web (Limited support)
- ❌ Desktop (Not tested)

## 🔐 Security Features

- ✅ JWT token authentication
- ✅ Secure token storage (FlutterSecureStorage)
- ✅ HTTPS support
- ✅ Input validation
- ✅ SQL injection prevention (backend)
- ✅ XSS protection (backend)
- ✅ Auto-logout on inactivity

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- **Your Name** - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Laravel team for the robust backend
- Provider package for state management
- Dio package for HTTP client

## 📞 Support

For support:
- Email: support@medimoms.com
- GitHub Issues: [Create an issue](https://github.com/yourusername/flutter_medimoms/issues)

## 🗺️ Roadmap

### Version 1.1
- [ ] Biometric authentication
- [ ] Push notifications
- [ ] Offline mode with local database
- [ ] PDF report generation
- [ ] QR code scanning

### Version 1.2
- [ ] Video consultation
- [ ] Prescription management
- [ ] Laboratory integration
- [ ] Advanced analytics

### Version 2.0
- [ ] AI-powered risk assessment
- [ ] Telemedicine platform
- [ ] IoT device connectivity

---

**Built with ❤️ using Flutter**

Version: 1.0.0  
Last Updated: January 2025
