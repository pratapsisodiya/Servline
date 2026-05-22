import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/core/config/appwrite_config.dart';
import 'package:servline/core/services/appwrite_service.dart';
import 'package:servline/models/location.dart';
import 'package:servline/models/service.dart';

/// Location Repository - handles location and service operations with Appwrite
class LocationRepository {
  final Databases _databases;

  LocationRepository(this._databases);

  /// Get all nearby locations
  Future<List<LocationModel>> getNearbyLocations({int limit = 20}) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        queries: [Query.equal('isOpen', true), Query.limit(limit)],
      );

      return result.documents
          .map((doc) => LocationModel.fromDocument(doc))
          .toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get locations: ${e.message}';
    }
  }

  /// Get location by ID
  Future<LocationModel> getLocationById(String locationId) async {
    try {
      final result = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        documentId: locationId,
      );

      return LocationModel.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to get location: ${e.message}';
    }
  }

  /// Search locations by name
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        queries: [Query.search('name', query), Query.limit(20)],
      );

      return result.documents
          .map((doc) => LocationModel.fromDocument(doc))
          .toList();
    } on AppwriteException catch (e) {
      throw 'Failed to search locations: ${e.message}';
    }
  }

  /// Get locations by type
  Future<List<LocationModel>> getLocationsByType(
    LocationType type, {
    int limit = 20,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        queries: [
          Query.equal('type', type.value),
          Query.equal('isOpen', true),
          Query.limit(limit),
        ],
      );

      return result.documents
          .map((doc) => LocationModel.fromDocument(doc))
          .toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get locations by type: ${e.message}';
    }
  }

  /// Get services for a location
  Future<List<ServiceModel>> getLocationServices(String locationId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.servicesCollection,
        queries: [
          Query.equal('locationId', locationId),
          Query.equal('isActive', true),
        ],
      );

      return result.documents
          .map((doc) => ServiceModel.fromDocument(doc))
          .toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get services: ${e.message}';
    }
  }

  /// Get service by ID
  Future<ServiceModel> getServiceById(String serviceId) async {
    try {
      final result = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.servicesCollection,
        documentId: serviceId,
      );

      return ServiceModel.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to get service: ${e.message}';
    }
  }

  // ── Admin write methods ────────────────────────────────────────────────────

  /// Get ALL locations owned by a specific admin
  Future<List<LocationModel>> getAllLocations({required String ownerId}) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        queries: [
          Query.equal('ownerId', ownerId),
          Query.limit(100),
          Query.orderDesc('\$createdAt'),
        ],
      );
      return result.documents.map((doc) => LocationModel.fromDocument(doc)).toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get locations: ${e.message}';
    }
  }

  /// Get ALL services for a location (including inactive) for admin
  Future<List<ServiceModel>> getAllLocationServices(String locationId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.servicesCollection,
        queries: [Query.equal('locationId', locationId)],
      );
      return result.documents.map((doc) => ServiceModel.fromDocument(doc)).toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get services: ${e.message}';
    }
  }

  Future<LocationModel> createLocation(LocationModel location) async {
    try {
      final result = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        documentId: ID.unique(),
        data: location.toJson(),
      );
      return LocationModel.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to create venue: ${e.message}';
    }
  }

  Future<LocationModel> updateLocation(LocationModel location) async {
    try {
      final result = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        documentId: location.id,
        data: location.toJson(),
      );
      return LocationModel.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to update venue: ${e.message}';
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.locationsCollection,
        documentId: locationId,
      );
    } on AppwriteException catch (e) {
      throw 'Failed to delete venue: ${e.message}';
    }
  }

  Future<ServiceModel> createService(ServiceModel service) async {
    try {
      final result = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.servicesCollection,
        documentId: ID.unique(),
        data: service.toJson(),
      );
      return ServiceModel.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to create service: ${e.message}';
    }
  }

  Future<ServiceModel> updateService(ServiceModel service) async {
    try {
      final result = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.servicesCollection,
        documentId: service.id,
        data: service.toJson(),
      );
      return ServiceModel.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to update service: ${e.message}';
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.servicesCollection,
        documentId: serviceId,
      );
    } on AppwriteException catch (e) {
      throw 'Failed to delete service: ${e.message}';
    }
  }
}

/// Provider for LocationRepository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  return LocationRepository(databases);
});
