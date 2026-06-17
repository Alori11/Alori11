import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import 'api_interceptor.dart';

class ApiClient {
  ApiClient._();

  static ApiClient? _instance;

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  late final Dio _dio;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.carchip.com/api/v1';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
        },
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_dio),
      ErrorMappingInterceptor(),
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: false,
        responseHeader: false,
        logPrint: (obj) => print('[API] $obj'),
      ),
    ]);

    _initialized = true;
  }

  Dio get dio {
    if (!_initialized) initialize();
    return _dio;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return dio.put<T>(path, data: data, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return dio.patch<T>(path, data: data, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return dio.delete<T>(path, data: data, options: options);
  }
}
