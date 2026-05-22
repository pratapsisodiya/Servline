import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as appwrite;

/// Location type enum - supports various venue types
enum LocationType {
  hospital,
  bank,
  clinic,
  government,
  retail,
  restaurant,
  salon,
  school,
  serviceCenter,
  theater,
  embassy,
  telecom,
  other,
}

extension LocationTypeExtension on LocationType {
  String get displayName {
    switch (this) {
      case LocationType.hospital:
        return 'Hospital';
      case LocationType.bank:
        return 'Bank';
      case LocationType.clinic:
        return 'Clinic';
      case LocationType.government:
        return 'Government Office';
      case LocationType.retail:
        return 'Retail Store';
      case LocationType.restaurant:
        return 'Restaurant';
      case LocationType.salon:
        return 'Salon & Spa';
      case LocationType.school:
        return 'School/College';
      case LocationType.serviceCenter:
        return 'Service Center';
      case LocationType.theater:
        return 'Theater/Cinema';
      case LocationType.embassy:
        return 'Embassy/Consulate';
      case LocationType.telecom:
        return 'Telecom Center';
      case LocationType.other:
        return 'Service';
    }
  }

  String get value {
    switch (this) {
      case LocationType.hospital:
        return 'hospital';
      case LocationType.bank:
        return 'bank';
      case LocationType.clinic:
        return 'clinic';
      case LocationType.government:
        return 'government';
      case LocationType.retail:
        return 'retail';
      case LocationType.restaurant:
        return 'restaurant';
      case LocationType.salon:
        return 'salon';
      case LocationType.school:
        return 'school';
      case LocationType.serviceCenter:
        return 'service_center';
      case LocationType.theater:
        return 'theater';
      case LocationType.embassy:
        return 'embassy';
      case LocationType.telecom:
        return 'telecom';
      case LocationType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case LocationType.hospital:
        return Icons.local_hospital;
      case LocationType.bank:
        return Icons.account_balance;
      case LocationType.clinic:
        return Icons.medical_services;
      case LocationType.government:
        return Icons.assured_workload;
      case LocationType.retail:
        return Icons.storefront;
      case LocationType.restaurant:
        return Icons.restaurant;
      case LocationType.salon:
        return Icons.content_cut;
      case LocationType.school:
        return Icons.school;
      case LocationType.serviceCenter:
        return Icons.build;
      case LocationType.theater:
        return Icons.movie;
      case LocationType.embassy:
        return Icons.location_city;
      case LocationType.telecom:
        return Icons.phone_android;
      case LocationType.other:
        return Icons.business;
    }
  }

  Color get color {
    switch (this) {
      case LocationType.hospital:
        return const Color(0xFFEF4444); // Red
      case LocationType.bank:
        return const Color(0xFF3B82F6); // Blue
      case LocationType.clinic:
        return const Color(0xFF22C55E); // Green
      case LocationType.government:
        return const Color(0xFF8B5CF6); // Purple
      case LocationType.retail:
        return const Color(0xFFF59E0B); // Amber
      case LocationType.restaurant:
        return const Color(0xFFF97316); // Orange
      case LocationType.salon:
        return const Color(0xFFEC4899); // Pink
      case LocationType.school:
        return const Color(0xFF06B6D4); // Cyan
      case LocationType.serviceCenter:
        return const Color(0xFF6366F1); // Indigo
      case LocationType.theater:
        return const Color(0xFFA855F7); // Purple
      case LocationType.embassy:
        return const Color(0xFF0EA5E9); // Sky Blue
      case LocationType.telecom:
        return const Color(0xFF14B8A6); // Teal
      case LocationType.other:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LocationType.hospital:
        return const Color(0xFFFEF2F2); // Red-50
      case LocationType.bank:
        return const Color(0xFFEFF6FF); // Blue-50
      case LocationType.clinic:
        return const Color(0xFFECFDF5); // Green-50
      case LocationType.government:
        return const Color(0xFFF5F3FF); // Violet-50
      case LocationType.retail:
        return const Color(0xFFFFFBEB); // Amber-50
      case LocationType.restaurant:
        return const Color(0xFFFFF7ED); // Orange-50
      case LocationType.salon:
        return const Color(0xFFFDF2F8); // Pink-50
      case LocationType.school:
        return const Color(0xFFECFEFF); // Cyan-50
      case LocationType.serviceCenter:
        return const Color(0xFFEEF2FF); // Indigo-50
      case LocationType.theater:
        return const Color(0xFFFAF5FF); // Purple-50
      case LocationType.embassy:
        return const Color(0xFFF0F9FF); // Sky-50
      case LocationType.telecom:
        return const Color(0xFFF0FDFA); // Teal-50
      case LocationType.other:
        return const Color(0xFFF9FAFB); // Gray-50
    }
  }

  static LocationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'hospital':
        return LocationType.hospital;
      case 'bank':
        return LocationType.bank;
      case 'clinic':
        return LocationType.clinic;
      case 'government':
        return LocationType.government;
      case 'retail':
        return LocationType.retail;
      case 'restaurant':
        return LocationType.restaurant;
      case 'salon':
        return LocationType.salon;
      case 'school':
        return LocationType.school;
      case 'service_center':
        return LocationType.serviceCenter;
      case 'theater':
        return LocationType.theater;
      case 'embassy':
        return LocationType.embassy;
      case 'telecom':
        return LocationType.telecom;
      default:
        return LocationType.other;
    }
  }
}

/// Location model with Appwrite serialization
class LocationModel {
  final String id;
  final String name;
  final String address;
  final String? branchName;
  final String distance;
  final int waitTimeMinutes;
  final int currentQueueSize;
  final LocationType type;
  final bool isOpen;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? phone;
  final String? qrCode;
  final bool hasPriorityQueue;
  final bool supportsAppointments;
  final String? ownerId; // userId of the admin who created this venue

  const LocationModel({
    required this.id,
    required this.name,
    required this.address,
    this.branchName,
    required this.distance,
    required this.waitTimeMinutes,
    this.currentQueueSize = 0,
    required this.type,
    this.isOpen = true,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.phone,
    this.qrCode,
    this.hasPriorityQueue = false,
    this.supportsAppointments = false,
    this.ownerId,
  });

  /// Create LocationModel from Appwrite Document
  factory LocationModel.fromDocument(appwrite.Document doc) {
    return LocationModel(
      id: doc.$id,
      name: doc.data['name'] ?? '',
      address: doc.data['address'] ?? '',
      branchName: doc.data['branchName'],
      distance: doc.data['distance'] ?? '0 km',
      waitTimeMinutes: doc.data['waitTimeMinutes'] ?? 0,
      currentQueueSize: doc.data['currentQueueSize'] ?? 0,
      type: LocationTypeExtension.fromString(doc.data['type'] ?? 'other'),
      isOpen: doc.data['isOpen'] ?? true,
      latitude: doc.data['latitude']?.toDouble(),
      longitude: doc.data['longitude']?.toDouble(),
      imageUrl: doc.data['imageUrl'],
      phone: doc.data['phone'],
      qrCode: doc.data['qrCode'],
      hasPriorityQueue: doc.data['hasPriorityQueue'] ?? false,
      supportsAppointments: doc.data['supportsAppointments'] ?? false,
      ownerId: doc.data['ownerId'],
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'branchName': branchName,
      'distance': distance,
      'waitTimeMinutes': waitTimeMinutes,
      'currentQueueSize': currentQueueSize,
      'type': type.value,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'phone': phone,
      'qrCode': qrCode,
      'hasPriorityQueue': hasPriorityQueue,
      'supportsAppointments': supportsAppointments,
      'ownerId': ownerId,
    };
  }

  /// Copy with new values
  LocationModel copyWith({
    String? id,
    String? name,
    String? address,
    String? branchName,
    String? distance,
    int? waitTimeMinutes,
    int? currentQueueSize,
    LocationType? type,
    bool? isOpen,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? phone,
    String? qrCode,
    bool? hasPriorityQueue,
    bool? supportsAppointments,
    String? ownerId,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      branchName: branchName ?? this.branchName,
      distance: distance ?? this.distance,
      waitTimeMinutes: waitTimeMinutes ?? this.waitTimeMinutes,
      currentQueueSize: currentQueueSize ?? this.currentQueueSize,
      type: type ?? this.type,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      qrCode: qrCode ?? this.qrCode,
      hasPriorityQueue: hasPriorityQueue ?? this.hasPriorityQueue,
      supportsAppointments: supportsAppointments ?? this.supportsAppointments,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  /// Get formatted wait time string
  String get formattedWaitTime {
    if (waitTimeMinutes < 60) {
      return '~$waitTimeMinutes min';
    } else {
      final hours = waitTimeMinutes ~/ 60;
      final mins = waitTimeMinutes % 60;
      return mins > 0 ? '~${hours}h ${mins}m' : '~${hours}h';
    }
  }
}
