import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/core/config/appwrite_config.dart';
import 'package:servline/core/services/appwrite_service.dart';
import 'package:servline/models/user.dart';

/// Authentication Repository - handles all auth operations with Appwrite
class AuthRepository {
  final Account _account;
  final Databases _databases;

  AuthRepository(this._account, this._databases);

  static const String _adminSecretCode = 'SERVLINE_ADMIN_2025';

  /// Create a new user account
  Future<User> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final result = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Create user document in database
      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: result.$id,
        data: {
          'email': email,
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
          'isGuest': false,
        },
      );

      // Auto login after registration
      await login(email: email, password: password);

      return User.fromAppwriteUser(result);
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  /// Login with email and password
  Future<User> login({required String email, required String password}) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final user = await _account.get();
      return User.fromAppwriteUser(user);
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  /// Login as anonymous guest
  /// Works offline - if Appwrite is unavailable, creates a local guest user
  Future<User> loginAsGuest() async {
    try {
      // First check if we already have a session
      try {
        final currentAccount = await _account.get();
        return User.fromAppwriteUser(currentAccount);
      } catch (_) {
        // No session, proceed to create one
      }

      await _account.createAnonymousSession();
      final user = await _account.get();
      return User.fromAppwriteUser(user);
    } on AppwriteException catch (e) {
      // If anonymous auth is disabled or failed, fallback to local guest
      // but only if it's not a session conflict
      if (e.code == 401 && e.message?.contains('Anonymous') == false) {
        // This might be a real session issue, but for guest we usually want to proceed
      }
      return User.guest();
    } catch (e) {
      return User.guest();
    }
  }

  /// Get current logged in user (reads isAdmin from DB document)
  Future<User?> getCurrentUser() async {
    try {
      final account = await _account.get();
      bool isAdmin = false;
      try {
        final doc = await _databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollection,
          documentId: account.$id,
        );
        isAdmin = doc.data['isAdmin'] ?? false;
      } catch (_) {}
      return User.fromAppwriteUser(account, isAdmin: isAdmin);
    } on AppwriteException {
      return null;
    }
  }

  /// Create an admin account (requires secret code)
  Future<User> createAdminAccount({
    required String email,
    required String password,
    required String name,
    required String secretCode,
  }) async {
    if (secretCode != _adminSecretCode) {
      throw 'Invalid admin secret code.';
    }
    try {
      final result = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollection,
        documentId: result.$id,
        data: {
          'email': email,
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
          'isGuest': false,
          'isAdmin': true,
        },
      );

      await login(email: email, password: password);
      return User.fromAppwriteUser(result, isAdmin: true);
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      await _account.get();
      return true;
    } on AppwriteException {
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  /// Send password recovery email
  Future<void> sendPasswordRecovery(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: 'https://servline.app/reset-password', // Update with your URL
      );
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile({String? name, String? phone, String? password}) async {
    try {
      models.User? updatedUser;

      if (name != null) {
        updatedUser = await _account.updateName(name: name);
      }

      if (phone != null && password != null) {
        await _account.updatePhone(phone: phone, password: password);
      }

      final user = updatedUser ?? await _account.get();
      return User.fromAppwriteUser(user);
    } on AppwriteException catch (e) {
      throw _handleAppwriteException(e);
    }
  }

  /// Handle Appwrite exceptions
  String _handleAppwriteException(AppwriteException e) {
    if (e.code == 401) {
      if (e.message?.contains('Anonymous') == true ||
          e.message?.contains('provider') == true) {
        return 'Guest login is currently unavailable. Please sign in with an account.';
      }
      return 'Invalid credentials. Please check your email and password.';
    }

    switch (e.code) {
      case 409:
        return 'An account with this email already exists.';
      case 429:
        return 'Too many requests. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final account = ref.watch(appwriteAccountProvider);
  final databases = ref.watch(appwriteDatabasesProvider);
  return AuthRepository(account, databases);
});
