import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/core/config/appwrite_config.dart';
import 'package:servline/core/services/appwrite_service.dart';
import 'package:servline/models/ticket.dart';

class QueueOperatorRepository {
  final Databases _databases;
  final Realtime _realtime;

  QueueOperatorRepository(this._databases, this._realtime);

  /// Fetch all active tickets for a service, ordered by queue position
  Future<List<Ticket>> getActiveTickets({
    required String locationId,
    required String serviceId,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        queries: [
          Query.equal('locationId', locationId),
          Query.equal('serviceId', serviceId),
          Query.equal('status', [
            TicketStatus.waiting.value,
            TicketStatus.called.value,
            TicketStatus.serving.value,
          ]),
          Query.orderAsc('issuedAt'),
          Query.limit(100),
        ],
      );
      return result.documents.map((d) => Ticket.fromDocument(d)).toList();
    } on AppwriteException catch (e) {
      throw 'Failed to load queue: ${e.message}';
    }
  }

  /// Call the next waiting ticket. Assigns counterNumber to it.
  /// Updates all remaining waiting tickets' positions.
  Future<void> callNext({
    required String locationId,
    required String serviceId,
    required String counterNumber,
  }) async {
    try {
      final waiting = await _getWaitingOnly(locationId, serviceId);
      if (waiting.isEmpty) return;

      // The ticket with position 1 is next
      final next = waiting.reduce(
        (a, b) => a.currentQueuePosition <= b.currentQueuePosition ? a : b,
      );

      // Call it
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: next.id,
        data: {
          'status': TicketStatus.called.value,
          'calledAt': DateTime.now().toIso8601String(),
          'currentQueuePosition': 0,
          'counterNumber': counterNumber,
        },
      );

      // Decrement position for everyone still waiting
      for (final t in waiting) {
        if (t.id == next.id) continue;
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.ticketsCollection,
          documentId: t.id,
          data: {'currentQueuePosition': t.currentQueuePosition - 1},
        );
      }
    } on AppwriteException catch (e) {
      throw 'Failed to call next: ${e.message}';
    }
  }

  /// Mark the currently called ticket as served (completed)
  Future<void> serveTicket(String ticketId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: ticketId,
        data: {
          'status': TicketStatus.completed.value,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw 'Failed to mark served: ${e.message}';
    }
  }

  /// Mark the currently called ticket as no-show
  Future<void> noShowTicket(String ticketId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: ticketId,
        data: {'status': TicketStatus.noShow.value},
      );
    } on AppwriteException catch (e) {
      throw 'Failed to mark no-show: ${e.message}';
    }
  }

  /// Return a called ticket back to the waiting queue (re-queue at the end)
  Future<void> returnToQueue({
    required Ticket ticket,
    required String locationId,
    required String serviceId,
  }) async {
    try {
      final waiting = await _getWaitingOnly(locationId, serviceId);
      final newPosition = waiting.length + 1;
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.ticketsCollection,
        documentId: ticket.id,
        data: {
          'status': TicketStatus.waiting.value,
          'calledAt': null,
          'counterNumber': null,
          'currentQueuePosition': newPosition,
        },
      );
    } on AppwriteException catch (e) {
      throw 'Failed to return to queue: ${e.message}';
    }
  }

  /// Subscribe to real-time changes for all tickets in a location's service
  RealtimeSubscription subscribeToQueue(void Function() onUpdate) {
    final subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.ticketsCollection}.documents',
    ]);
    subscription.stream.listen((_) => onUpdate());
    return subscription;
  }

  Future<List<Ticket>> _getWaitingOnly(
    String locationId,
    String serviceId,
  ) async {
    final result = await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.ticketsCollection,
      queries: [
        Query.equal('locationId', locationId),
        Query.equal('serviceId', serviceId),
        Query.equal('status', TicketStatus.waiting.value),
        Query.orderAsc('currentQueuePosition'),
        Query.limit(100),
      ],
    );
    return result.documents.map((d) => Ticket.fromDocument(d)).toList();
  }
}

final queueOperatorRepositoryProvider = Provider<QueueOperatorRepository>((ref) {
  return QueueOperatorRepository(
    ref.watch(appwriteDatabasesProvider),
    ref.watch(appwriteRealtimeProvider),
  );
});
