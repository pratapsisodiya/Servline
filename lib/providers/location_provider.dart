import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/models/location.dart';
import 'package:servline/models/service.dart';
import 'package:servline/repositories/location_repository.dart';

/// Location state
class LocationState {
  final List<LocationModel> locations;
  final LocationModel? selectedLocation;
  final List<ServiceModel> services;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.locations = const [],
    this.selectedLocation,
    this.services = const [],
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    List<LocationModel>? locations,
    LocationModel? selectedLocation,
    List<ServiceModel>? services,
    bool? isLoading,
    String? error,
    bool clearSelectedLocation = false,
  }) {
    return LocationState(
      locations: locations ?? this.locations,
      selectedLocation: clearSelectedLocation
          ? null
          : (selectedLocation ?? this.selectedLocation),
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Location Notifier with Appwrite integration
class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState();
  }

  LocationRepository get _locationRepo => ref.read(locationRepositoryProvider);

  /// Load nearby locations
  Future<void> loadNearbyLocations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locations = await _locationRepo.getNearbyLocations();
      state = state.copyWith(locations: locations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Search locations
  Future<void> searchLocations(String query) async {
    if (query.isEmpty) {
      await loadNearbyLocations();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final locations = await _locationRepo.searchLocations(query);
      state = state.copyWith(locations: locations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select a location and load its services
  Future<void> selectLocation(LocationModel location) async {
    state = state.copyWith(
      selectedLocation: location,
      isLoading: true,
      services: [],
    );

    try {
      final services = await _locationRepo.getLocationServices(location.id);
      state = state.copyWith(services: services, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load a location by ID, fetch it from Appwrite, then select it
  Future<void> loadLocationById(String locationId) async {
    if (state.selectedLocation?.id == locationId && state.services.isNotEmpty) return;
    state = state.copyWith(isLoading: true, error: null, services: []);
    try {
      final location = await _locationRepo.getLocationById(locationId);
      await selectLocation(location);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear selected location
  void clearSelection() {
    state = state.copyWith(clearSelectedLocation: true, services: []);
  }

  /// Get locations by type
  Future<void> loadLocationsByType(LocationType type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locations = await _locationRepo.getLocationsByType(type);
      state = state.copyWith(locations: locations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Location provider
final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);

/// Nearby locations provider (with mock data fallback)
final nearbyLocationsProvider = Provider<List<LocationModel>>((ref) {
  final state = ref.watch(locationProvider);

  // Return mock data if Appwrite isn't configured yet
  if (state.locations.isEmpty && !state.isLoading) {
    return [
      LocationModel(
        id: '1',
        name: 'City Hospital',
        address: '123 Medical Center Drive',
        distance: '0.5 km',
        waitTimeMinutes: 15,
        currentQueueSize: 5,
        type: LocationType.hospital,
        isOpen: true,
        hasPriorityQueue: true,
        supportsAppointments: true,
      ),
      LocationModel(
        id: '2',
        name: 'First National Bank',
        address: '456 Financial District',
        branchName: 'Downtown Branch',
        distance: '1.2 km',
        waitTimeMinutes: 20,
        currentQueueSize: 8,
        type: LocationType.bank,
        isOpen: true,
        hasPriorityQueue: true,
      ),
      LocationModel(
        id: '3',
        name: 'QuickCare Clinic',
        address: '789 Health Street',
        distance: '2.0 km',
        waitTimeMinutes: 10,
        currentQueueSize: 3,
        type: LocationType.clinic,
        isOpen: true,
        supportsAppointments: true,
      ),
      LocationModel(
        id: '4',
        name: 'RTO Office',
        address: '321 Government Complex',
        distance: '3.5 km',
        waitTimeMinutes: 45,
        currentQueueSize: 25,
        type: LocationType.government,
        isOpen: true,
        hasPriorityQueue: true,
        supportsAppointments: true,
      ),
      LocationModel(
        id: '5',
        name: 'Style Studio Salon',
        address: '55 Fashion Street',
        distance: '0.8 km',
        waitTimeMinutes: 5,
        currentQueueSize: 2,
        type: LocationType.salon,
        isOpen: true,
        supportsAppointments: true,
      ),
      LocationModel(
        id: '6',
        name: 'City High School',
        address: '100 Education Lane',
        branchName: 'Admissions Office',
        distance: '2.5 km',
        waitTimeMinutes: 30,
        currentQueueSize: 12,
        type: LocationType.school,
        isOpen: true,
      ),
      LocationModel(
        id: '7',
        name: 'Spice Garden Restaurant',
        address: '88 Food Court',
        distance: '1.0 km',
        waitTimeMinutes: 8,
        currentQueueSize: 4,
        type: LocationType.restaurant,
        isOpen: true,
      ),
    ];
  }

  return state.locations;
});

/// Selected location provider
final selectedLocationProvider = Provider<LocationModel?>((ref) {
  return ref.watch(locationProvider).selectedLocation;
});

/// Location services provider
final locationServicesProvider = Provider<List<ServiceModel>>((ref) {
  final state = ref.watch(locationProvider);

  // Return mock services only as fallback (no Appwrite connection) — not during loading
  if (state.services.isEmpty && !state.isLoading && state.selectedLocation != null && state.error == null) {
    return [
      ServiceModel(
        id: '1',
        name: 'Account Opening',
        locationId: state.selectedLocation!.id,
        estimatedWaitMinutes: 5,
        currentQueueSize: 2,
      ),
      ServiceModel(
        id: '2',
        name: 'Cash Services',
        locationId: state.selectedLocation!.id,
        estimatedWaitMinutes: 12,
        currentQueueSize: 4,
      ),
      ServiceModel(
        id: '3',
        name: 'Loan Enquiry',
        locationId: state.selectedLocation!.id,
        estimatedWaitMinutes: 2,
        currentQueueSize: 1,
      ),
      ServiceModel(
        id: '4',
        name: 'General Support',
        locationId: state.selectedLocation!.id,
        estimatedWaitMinutes: 0,
        currentQueueSize: 0,
      ),
    ];
  }

  return state.services;
});
