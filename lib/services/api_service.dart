import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  ApiService._();

  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;

  late Dio _dio;

  Dio get dio => _dio;

  void initialize() {
    final baseUrl = AppConfig.apiUrl;
    debugPrint('🌐 Initializing API Service');
    debugPrint('   Base URL: $baseUrl');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.instance.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            if (AppConfig.enableDebugLogs) {
              debugPrint('🔑 Token present: ${token.substring(0, 20)}...');
            }
          } else {
            if (AppConfig.enableDebugLogs) {
              debugPrint('⚠️ No token found');
            }
          }

          if (AppConfig.enableDebugLogs) {
            debugPrint('🌐 API Request: ${options.method} ${options.path}');
            debugPrint('   Headers: ${options.headers}');
            if (options.data != null) {
              debugPrint('   Data: ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (AppConfig.enableDebugLogs) {
            debugPrint('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
            debugPrint('   Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (AppConfig.enableDebugLogs) {
            debugPrint('❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
            debugPrint('   Message: ${error.message}');
            debugPrint('   Response: ${error.response?.data}');
          }

          // Only clear auth for audit-logs if it's actually unauthorized
          // Don't clear for other 401s that might be temporary
          if (error.response?.statusCode == 401 && error.requestOptions.path.contains('/audit-logs')) {
            // Don't clear auth data, just let the error propagate
            debugPrint('🔒 Unauthorized on audit-logs - keeping auth data');
          } else if (error.response?.statusCode == 401) {
            await StorageService.instance.clearAuthData();
            debugPrint('🔒 Unauthorized - Cleared auth data');
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    String errorMessage = 'An error occurred';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timeout - Backend not responding';
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'Cannot connect to backend server';
    } else if (error.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Request timeout - Backend not responding';
    } else if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          errorMessage = data['message'] ?? 'Bad request';
          break;
        case 401:
          errorMessage = 'Invalid credentials';
          break;
        case 403:
          errorMessage = 'Access forbidden';
          break;
        case 404:
          errorMessage = 'Resource not found';
          break;
        case 422:
          if (data is Map && data.containsKey('errors')) {
            final errors = data['errors'] as Map;
            errorMessage = errors.values.first[0];
          } else {
            errorMessage = data['message'] ?? 'Validation error';
          }
          break;
        case 500:
          errorMessage = 'Server error. Please try again later.';
          break;
        default:
          errorMessage = data['message'] ?? 'An error occurred';
      }
    } else {
      errorMessage = 'Cannot connect to backend server';
    }

    return errorMessage;
  }
}
