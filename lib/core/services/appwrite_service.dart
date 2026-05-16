import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/core/config/appwrite_config.dart';

/// Appwrite Service - Singleton client for all Appwrite operations
class AppwriteService {
  static AppwriteService? _instance;
  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  late final Realtime _realtime;
  late final Storage _storage;

  AppwriteService._() {
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    _account = Account(_client);
    _databases = Databases(_client);
    _realtime = Realtime(_client);
    _storage = Storage(_client);
  }

  static AppwriteService get instance {
    _instance ??= AppwriteService._();
    return _instance!;
  }

  // Getters for services
  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Realtime get realtime => _realtime;
  Storage get storage => _storage;
}

// Riverpod Providers for Appwrite Services
final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService.instance;
});

final appwriteAccountProvider = Provider<Account>((ref) {
  return ref.watch(appwriteServiceProvider).account;
});

final appwriteDatabasesProvider = Provider<Databases>((ref) {
  return ref.watch(appwriteServiceProvider).databases;
});

final appwriteRealtimeProvider = Provider<Realtime>((ref) {
  return ref.watch(appwriteServiceProvider).realtime;
});

final appwriteStorageProvider = Provider<Storage>((ref) {
  return ref.watch(appwriteServiceProvider).storage;
});
