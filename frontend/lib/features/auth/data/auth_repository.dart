import '../../../core/network/network_exceptions.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_remote_datasource.dart';
import 'models/auth_response_model.dart';
import 'models/user_model.dart';
import 'dart:convert';

class AuthRepository {
  final AuthRemoteDatasource _datasource;
  final SecureStorage _storage;

  AuthRepository({
    AuthRemoteDatasource? datasource,
    SecureStorage? storage,
  })  : _datasource = datasource ?? AuthRemoteDatasource(),
        _storage = storage ?? SecureStorage.instance;

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _datasource.login(email: email, password: password);
      await _saveSession(response);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _datasource.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      await _saveSession(response);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> phoneLogin({required String phone}) async {
    try {
      await _datasource.phoneLogin(phone: phone);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponseModel> verifyOTP({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _datasource.verifyOTP(phone: phone, code: code);
      await _saveSession(response);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _datasource.logout();
    } catch (_) {
      // Even if logout fails on server, clear local tokens
    } finally {
      await _storage.clearTokens();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final userJson = await _storage.getUser();
      if (userJson != null) {
        return UserModel.fromJson(json.decode(userJson) as Map<String, dynamic>);
      }
      // Fetch from server
      final user = await _datasource.getMe();
      await _storage.saveUser(json.encode(user.toJson()));
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _datasource.forgotPassword(email: email);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> isLoggedIn() async {
    return _storage.hasToken();
  }

  Future<void> _saveSession(AuthResponseModel response) async {
    await Future.wait([
      _storage.saveToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      ),
      _storage.saveUser(json.encode(response.user.toJson())),
    ]);
  }

  Exception _handleError(dynamic error) {
    if (error is NetworkException) return error;
    return NetworkException(message: error.toString());
  }
}
