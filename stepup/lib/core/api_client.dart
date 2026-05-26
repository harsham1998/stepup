import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ApiError {
  final String message;
  final int? statusCode;
  const _ApiError(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiClient {
  static final instance = ApiClient._();
  ApiClient._();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stepup-production-ebd2.up.railway.app',
  );

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ))..interceptors.addAll([
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          debugPrint('[API] WARNING: no session token for ${options.path}');
        }
        debugPrint('[API] --> ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API] <-- ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('[API] ERR ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}');
        handler.next(error);
      },
    ),
  ]);

  Future<dynamic> get(String path, [Map<String, dynamic>? params]) async {
    final r = await _dio.get(path, queryParameters: params);
    return r.data;
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post(path, data: body);
      return r.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMsg = data is Map ? (data['error'] as String?) : null;
      final statusCode = e.response?.statusCode;
      throw _ApiError(serverMsg ?? e.message ?? 'Request failed', statusCode);
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final r = await _dio.put(path, data: body);
    return r.data;
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final r = await _dio.patch(path, data: body);
    return r.data;
  }
}
