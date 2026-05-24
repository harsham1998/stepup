import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  static final instance = ApiClient._();
  ApiClient._();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stepup-production-ebd2.up.railway.app',
  );

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (error, handler) {
      handler.next(error);
    },
  ));

  Future<dynamic> get(String path, [Map<String, dynamic>? params]) async {
    final r = await _dio.get(path, queryParameters: params);
    return r.data;
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final r = await _dio.post(path, data: body);
    return r.data;
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final r = await _dio.put(path, data: body);
    return r.data;
  }
}
