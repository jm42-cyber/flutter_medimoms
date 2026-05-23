import '../config/api_endpoints.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final _api = ApiService.instance;
  final _storage = StorageService.instance;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiEndpoints.login,
      data: {
        'username_or_email': email,
        'password': password,
      },
    );

    final data = response.data;
    
    if (data['token'] != null) {
      await _storage.saveToken(data['token']);
    }

    if (data['user'] != null) {
      final user = data['user'];
      await _storage.saveUserId(user['id']);
      await _storage.saveUserName(user['full_name'] ?? '${user['first_name']} ${user['last_name']}');
      await _storage.saveUserEmail(user['email']);
      await _storage.saveUserRole(user['role']);
    }

    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    final response = await _api.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      },
    );

    final data = response.data;
    
    if (data['token'] != null) {
      await _storage.saveToken(data['token']);
    }

    if (data['user'] != null) {
      final user = data['user'];
      await _storage.saveUserId(user['id']);
      await _storage.saveUserName(user['full_name'] ?? '${user['first_name']} ${user['last_name']}');
      await _storage.saveUserEmail(user['email']);
      await _storage.saveUserRole(user['role']);
    }

    return data;
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await _storage.clearAuthData();
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _api.get(ApiEndpoints.me);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final response = await _api.put(
      ApiEndpoints.updateProfile,
      data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      },
    );

    final user = response.data['user'];
    if (user != null) {
      if (user['full_name'] != null) await _storage.saveUserName(user['full_name']);
      if (user['email'] != null) await _storage.saveUserEmail(user['email']);
    }

    return response.data;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _api.put(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );

    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await _api.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _api.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _api.post(
      ApiEndpoints.verifyOtp,
      data: {
        'email': email,
        'otp': otp,
      },
    );

    return response.data;
  }

  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    final response = await _api.post(
      ApiEndpoints.resendOtp,
      data: {'email': email},
    );

    return response.data;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }
}
