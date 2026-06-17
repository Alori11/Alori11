import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/app_strings.dart';
import 'network_exceptions.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        _pendingRequests.add(err.requestOptions);
        return;
      }

      _isRefreshing = true;

      try {
        final refreshToken = await SecureStorage.instance.getRefreshToken();
        if (refreshToken == null) {
          await SecureStorage.instance.clearTokens();
          handler.reject(err);
          return;
        }

        final response = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(
            headers: {'Authorization': null},
          ),
        );

        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await SecureStorage.instance.saveToken(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry pending requests
          for (final pending in _pendingRequests) {
            pending.headers['Authorization'] = 'Bearer $newAccessToken';
            await dio.fetch(pending);
          }
          _pendingRequests.clear();

          // Retry original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
        } else {
          await SecureStorage.instance.clearTokens();
          handler.reject(err);
        }
      } catch (_) {
        await SecureStorage.instance.clearTokens();
        _pendingRequests.clear();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    NetworkException networkException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        networkException = const TimeoutException();
        break;
      case DioExceptionType.connectionError:
        networkException = const ConnectionException();
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = _extractMessage(err.response?.data) ??
            AppStrings.errorGeneric;

        switch (statusCode) {
          case 401:
            networkException = const UnauthorizedException();
            break;
          case 403:
            networkException = const ForbiddenException();
            break;
          case 404:
            networkException = NotFoundException(message: message);
            break;
          case 422:
            networkException = ValidationException(
              message: message,
              errors: err.response?.data is Map
                  ? (err.response?.data as Map).cast<String, dynamic>()
                  : null,
            );
            break;
          case 500:
          case 502:
          case 503:
            networkException = ServerException(message: message);
            break;
          default:
            networkException = NetworkException(
              message: message,
              statusCode: statusCode,
            );
        }
        break;
      default:
        networkException = const NetworkException(
          message: AppStrings.errorGeneric,
        );
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: networkException,
        message: networkException.message,
        type: err.type,
        response: err.response,
      ),
    );
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['msg'] as String?;
    }
    return null;
  }
}
