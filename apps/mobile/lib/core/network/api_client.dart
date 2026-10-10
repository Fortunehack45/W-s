import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AppApiException represents normalized API error responses.
class AppApiException implements Exception {
  AppApiException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'AppApiException(code: $code, message: $message)';
}

/// ApiClient wraps Dio with authentication token injection and error handling.
class ApiClient {
  ApiClient({String baseUrl = 'http://localhost:8080/api/v1'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.data is Map<String, dynamic>) {
          final data = e.response!.data as Map<String, dynamic>;
          if (data['error'] is Map<String, dynamic>) {
            final errObj = data['error'] as Map<String, dynamic>;
            return handler.reject(DioException(
              requestOptions: e.requestOptions,
              error: AppApiException(
                code: errObj['code']?.toString() ?? 'UNKNOWN_ERROR',
                message: errObj['message']?.toString() ?? 'An error occurred',
              ),
            ));
          }
        }
        return handler.next(e);
      },
    ));
  }

  late final Dio _dio;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Dio get client => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
