import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/models/auth_state.dart';
import 'package:servline/models/user.dart';
import 'package:servline/repositories/auth_repository.dart';

/// Authentication Notifier with Appwrite integration
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Check for existing session on startup
    _checkExistingSession();
    return AuthState.initial();
  }

  AuthRepository get _authRepo => ref.read(authRepositoryProvider);

  /// Check if user has existing session
  Future<void> _checkExistingSession() async {
    state = AuthState.loading();
    try {
      final user = await _authRepo.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.initial();
      }
    } catch (e) {
      state = AuthState.initial();
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepo.login(email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Register new account
  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepo.createAccount(
        email: email,
        password: password,
        name: name,
      );
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Login as guest
  Future<bool> loginAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepo.loginAsGuest();
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepo.logout();
    } catch (e) {
      // Ignore logout errors
    }
    state = AuthState.initial();
  }

  /// Send password recovery email
  Future<bool> sendPasswordRecovery(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepo.sendPasswordRecovery(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});
