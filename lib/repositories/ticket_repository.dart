import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/core/config/appwrite_config.dart';
import 'package:servline/core/services/appwrite_service.dart';
import 'package:servline/models/ticket.dart';

/// Ticket Repository - handles queue ticket operations with Appwrite
class TicketRepository {
  final Databases _databases;
  final Realtime _realtime;

  TicketRepository(this._databases, this._realtime);

  /// Create a new queue ticket
  Future<Ticket> createTicket({
    required String userId,
    required String locationId,
    required String locationName,
    required String serviceId,
    required String serviceName,
    int headCount = 1,
    DateTime? scheduledTime,
  }) async {
    try {
      // Generate token number (in production, this would be server-side)
      final tokenNumber = _generateTokenNumber();

      // Get current queue position (only for immediate queue)
      final queuePosition = scheduledTime == null
          ? await _getCurrentQueuePosition(locationId, serviceId)
          : 0; // Appointments don't have a queue position yet

      final result = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'locationId': locationId,
          'locationName': locationName,
          'serviceId': serviceId,
          'serviceName': serviceName,
          'tokenNumber': tokenNumber,
          'headCount': headCount,
          'currentQueuePosition': queuePosition,
          'totalInQueue': queuePosition,
          'estimatedWaitMinutes': scheduledTime == null
              ? queuePosition * 5
              : 0,
          'status': scheduledTime != null
              ? TicketStatus.scheduled.value
              : TicketStatus.waiting.value,
          'issuedAt': DateTime.now().toIso8601String(),
          'scheduledTime': scheduledTime?.toIso8601String(),
          'notifyBySms': false,
        },
      );

      return Ticket.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to create ticket: ${e.message}';
    }
  }

  /// Get active ticket for user
  Future<Ticket?> getActiveTicket(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', [
            TicketStatus.waiting.value,
            TicketStatus.called.value,
            TicketStatus.serving.value,
          ]),
          Query.orderDesc('issuedAt'),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) return null;
      return Ticket.fromDocument(result.documents.first);
    } on AppwriteException catch (e) {
      throw 'Failed to get active ticket: ${e.message}';
    }
  }

  /// Get scheduled tickets (appointments) for user
  Future<List<Ticket>> getScheduledTickets(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', TicketStatus.scheduled.value),
          Query.orderAsc('scheduledTime'), // Show nearest first
        ],
      );

      return result.documents.map((doc) => Ticket.fromDocument(doc)).toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get appointments: ${e.message}';
    }
  }

  /// Get ticket by ID
  Future<Ticket> getTicketById(String ticketId) async {
    try {
      final result = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: ticketId,
      );

      return Ticket.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to get ticket: ${e.message}';
    }
  }

  /// Cancel a ticket
  Future<Ticket> cancelTicket(String ticketId) async {
    try {
      final result = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: ticketId,
        data: {
          'status': TicketStatus.cancelled.value,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      return Ticket.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to cancel ticket: ${e.message}';
    }
  }

  /// Update SMS notification preference
  Future<Ticket> updateSmsPreference(String ticketId, bool notifyBySms) async {
    try {
      final result = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: ticketId,
        data: {'notifyBySms': notifyBySms},
      );

      return Ticket.fromDocument(result);
    } on AppwriteException catch (e) {
      throw 'Failed to update SMS preference: ${e.message}';
    }
  }

  /// Get ticket history for user
  Future<List<Ticket>> getTicketHistory(String userId, {int limit = 20}) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('issuedAt'),
          Query.limit(limit),
        ],
      );

      return result.documents.map((doc) => Ticket.fromDocument(doc)).toList();
    } on AppwriteException catch (e) {
      throw 'Failed to get ticket history: ${e.message}';
    }
  }

  /// Subscribe to real-time ticket updates
  RealtimeSubscription subscribeToTicketUpdates(
    String ticketId,
    void Function(Ticket) onUpdate,
  ) {
    final subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.ticketsCollection}.documents.$ticketId',
    ]);

    subscription.stream.listen((event) {
      if (event.payload.isNotEmpty) {
        // Parse the updated ticket from the event
        final ticket = Ticket(
          id: event.payload['\$id'] ?? ticketId,
          tokenNumber: event.payload['tokenNumber'] ?? '',
          userId: event.payload['userId'] ?? '',
          locationId: event.payload['locationId'] ?? '',
          locationName: event.payload['locationName'] ?? '',
          serviceId: event.payload['serviceId'] ?? '',
          serviceName: event.payload['serviceName'] ?? '',
          counterNumber: event.payload['counterNumber'],
          currentQueuePosition: event.payload['currentQueuePosition'] ?? 0,
          totalInQueue: event.payload['totalInQueue'] ?? 0,
          estimatedWaitMinutes: event.payload['estimatedWaitMinutes'] ?? 0,
          status: TicketStatusExtension.fromString(
            event.payload['status'] ?? 'waiting',
          ),
          issuedAt:
              DateTime.tryParse(event.payload['issuedAt'] ?? '') ??
              DateTime.now(),
          calledAt: event.payload['calledAt'] != null
              ? DateTime.tryParse(event.payload['calledAt'])
              : null,
          completedAt: event.payload['completedAt'] != null
              ? DateTime.tryParse(event.payload['completedAt'])
              : null,
          scheduledTime: event.payload['scheduledTime'] != null
              ? DateTime.tryParse(event.payload['scheduledTime'])
              : null,
          notifyBySms: event.payload['notifyBySms'] ?? false,
        );
        onUpdate(ticket);
      }
    });

    return subscription;
  }

  /// Generate a token number
  String _generateTokenNumber() {
    final now = DateTime.now();
    final number = (now.hour * 1000 + now.minute * 100 + now.second) % 10000;
    return number.toString().padLeft(4, '0');
  }

  /// Get current queue position for a service
  Future<int> _getCurrentQueuePosition(
    String locationId,
    String serviceId,
  ) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        queries: [
          Query.equal('locationId', locationId),
          Query.equal('serviceId', serviceId),
          Query.equal('status', TicketStatus.waiting.value),
        ],
      );

      return result.documents.length + 1;
    } catch (e) {
      return 1;
    }
  }
}

/// Provider for TicketRepository
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  final realtime = ref.watch(appwriteRealtimeProvider);
  return TicketRepository(databases, realtime);
});
