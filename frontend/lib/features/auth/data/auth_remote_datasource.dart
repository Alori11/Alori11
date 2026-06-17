import '../../../core/network/api_client.dart';
import 'models/auth_response_model.dart';
import 'models/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient _client;

  AuthRemoteDatasource({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> phoneLogin({required String phone}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/phone-login',
      data: {'phone': phone},
    );
    return response.data!;
  }

  Future<AuthResponseModel> verifyOTP({
    required String phone,
    required String code,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {'phone': phone, 'code': code},
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<AuthResponseModel> refreshToken({required String token}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': token},
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<void> logout() async {
    await _client.post('/auth/logout');
  }

  Future<UserModel> getMe() async {
    final response = await _client.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(response.data!);
  }

  Future<void> forgotPassword({required String email}) async {
    await _client.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }
}
