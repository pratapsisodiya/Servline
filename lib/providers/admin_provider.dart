import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/models/location.dart';
import 'package:servline/models/service.dart';
import 'package:servline/providers/auth_provider.dart';
import 'package:servline/repositories/location_repository.dart';

class AdminState {
  final List<LocationModel> venues;
  final List<ServiceModel> services;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.venues = const [],
    this.services = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<LocationModel>? venues,
    List<ServiceModel>? services,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminState(
      venues: venues ?? this.venues,
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() => const AdminState();

  LocationRepository get _repo => ref.read(locationRepositoryProvider);
  String get _ownerId => ref.read(currentUserProvider)?.id ?? '';

  Future<void> loadVenues() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final venues = await _repo.getAllLocations(ownerId: _ownerId);
      state = state.copyWith(venues: venues, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createVenue(LocationModel location) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Stamp ownerId so this venue belongs to this admin only
      final created = await _repo.createLocation(
        location.copyWith(ownerId: _ownerId),
      );
      state = state.copyWith(
        venues: [created, ...state.venues],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateVenue(LocationModel location) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.updateLocation(location);
      state = state.copyWith(
        venues: state.venues.map((v) => v.id == updated.id ? updated : v).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteVenue(String locationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteLocation(locationId);
      state = state.copyWith(
        venues: state.venues.where((v) => v.id != locationId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadServices(String locationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final services = await _repo.getAllLocationServices(locationId);
      state = state.copyWith(services: services, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createService(ServiceModel service) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repo.createService(service);
      state = state.copyWith(
        services: [created, ...state.services],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateService(ServiceModel service) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.updateService(service);
      state = state.copyWith(
        services: state.services.map((s) => s.id == updated.id ? updated : s).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteService(serviceId);
      state = state.copyWith(
        services: state.services.where((s) => s.id != serviceId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(
  AdminNotifier.new,
);
