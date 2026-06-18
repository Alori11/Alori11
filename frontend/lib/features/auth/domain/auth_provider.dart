import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/google_auth_service.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) {
      final user = await _repository.getCurrentUser();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.login(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> phoneLogin({required String phone}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.phoneLogin(phone: phone);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyOTP({
    required String phone,
    required String code,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.verifyOTP(phone: phone, code: code);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final idToken = await GoogleAuthService.instance.signIn();
      if (idToken == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return false;
      }
      final response = await _repository.loginWithGoogle(idToken: idToken);
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.forgotPassword(email: email);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
