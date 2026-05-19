import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servline/models/ticket.dart';
import 'package:servline/providers/auth_provider.dart';
import 'package:servline/repositories/ticket_repository.dart';
import 'package:servline/core/services/queue_alert_service.dart';

/// Global navigator key for programmatic navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Ticket state
class TicketState {
  final Ticket? activeTicket;
  final List<Ticket> appointments;
  final List<Ticket> history;
  final bool isLoading;
  final String? error;

  const TicketState({
    this.activeTicket,
    this.appointments = const [],
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  TicketState copyWith({
    Ticket? activeTicket,
    List<Ticket>? appointments,
    List<Ticket>? history,
    bool? isLoading,
    String? error,
    bool clearActiveTicket = false,
  }) {
    return TicketState(
      activeTicket: clearActiveTicket
          ? null
          : (activeTicket ?? this.activeTicket),
      appointments: appointments ?? this.appointments,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Ticket Notifier with Appwrite integration, realtime updates, and queue alerts
class TicketNotifier extends Notifier<TicketState> {
  RealtimeSubscription? _subscription;
  int? _lastQueuePosition;

  @override
  TicketState build() {
    ref.onDispose(() {
      _subscription?.close();
      queueAlertService.reset();
    });
    return const TicketState();
  }

  TicketRepository get _ticketRepo => ref.read(ticketRepositoryProvider);

  /// Load active ticket for current user
  Future<void> loadActiveTicket() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final ticket = await _ticketRepo.getActiveTicket(user.id);
      final appointments = await _ticketRepo.getScheduledTickets(
        user.id,
      ); // Fetch appointments
      state = state.copyWith(
        activeTicket: ticket,
        appointments: appointments, // Update appointments in state
        isLoading: false,
      );

      // Subscribe to realtime updates if ticket exists
      if (ticket != null) {
        _lastQueuePosition = ticket.currentQueuePosition;
        _subscribeToTicket(ticket.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new ticket
  Future<bool> joinQueue({
    required String locationId,
    required String locationName,
    required String serviceId,
    required String serviceName,
    int headCount = 1,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    if (state.activeTicket != null) {
      state = state.copyWith(error: 'You already have an active ticket. Cancel it first.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final ticket = await _ticketRepo.createTicket(
        userId: user.id,
        locationId: locationId,
        locationName: locationName,
        serviceId: serviceId,
        serviceName: serviceName,
        headCount: headCount,
      );
      state = state.copyWith(activeTicket: ticket, isLoading: false);
      _lastQueuePosition = ticket.currentQueuePosition;
      _subscribeToTicket(ticket.id);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Book an appointment
  Future<bool> bookAppointment({
    required String locationId,
    required String locationName,
    required String serviceId,
    required String serviceName,
    required DateTime scheduledTime,
    int headCount = 1,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Just create the ticket with scheduled status, don't set it as 'active' immediately
      // unless we want to show it. For now, let's say active ticket is only for immediate queue.
      // Or maybe we treat it as active if it's the only one.
      // Let's NOT set it as activeTicket for now, as that drives the 'Waiting' screen.
      // We will need a separate 'My Appointments' list later.

      await _ticketRepo.createTicket(
        userId: user.id,
        locationId: locationId,
        locationName: locationName,
        serviceId: serviceId,
        serviceName: serviceName,
        headCount: headCount,
        scheduledTime: scheduledTime,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Cancel current ticket
  Future<void> cancelTicket() async {
    final ticket = state.activeTicket;
    if (ticket == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ticketRepo.cancelTicket(ticket.id);
      _subscription?.close();
      queueAlertService.reset();
      _lastQueuePosition = null;
      state = state.copyWith(isLoading: false, clearActiveTicket: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update SMS notification preference
  Future<void> updateSmsPreference(bool notifyBySms) async {
    final ticket = state.activeTicket;
    if (ticket == null) return;

    try {
      final updatedTicket = await _ticketRepo.updateSmsPreference(
        ticket.id,
        notifyBySms,
      );
      state = state.copyWith(activeTicket: updatedTicket);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load ticket history
  Future<void> loadHistory() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _ticketRepo.getTicketHistory(user.id);
      state = state.copyWith(history: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Subscribe to realtime ticket updates
  void _subscribeToTicket(String ticketId) {
    _subscription?.close();
    _subscription = _ticketRepo.subscribeToTicketUpdates(ticketId, (
      updatedTicket,
    ) async {
      state = state.copyWith(activeTicket: updatedTicket);

      // Check for queue position changes and trigger alerts
      await _checkQueuePositionChange(updatedTicket);
    });
  }

  /// Check if queue position changed and trigger appropriate alerts
  Future<void> _checkQueuePositionChange(Ticket ticket) async {
    final newPosition = ticket.currentQueuePosition;

    // Skip if position hasn't changed
    if (_lastQueuePosition == newPosition) return;

    _lastQueuePosition = newPosition;

    // Check for "Be Ready" (position = 1)
    if (newPosition == 1) {
      await queueAlertService.checkQueuePosition(
        currentPosition: newPosition,
        locationName: ticket.locationName,
        context: null,
      );
      // Just notification, no navigation needed for position 1
    }

    // Check for "Your Turn" (position = 0 or status is 'called')
    if (newPosition == 0 || ticket.status == TicketStatus.called) {
      // Trigger intense vibration and navigate to YourTurnScreen
      final shouldNavigate = await queueAlertService.checkQueuePosition(
        currentPosition: 0,
        locationName: ticket.locationName,
        context: null,
      );

      if (shouldNavigate) {
        // Use router to navigate to YourTurnScreen
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          context.go('/your-turn');
        }
      }
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Ticket provider
final ticketProvider = NotifierProvider<TicketNotifier, TicketState>(
  TicketNotifier.new,
);

/// Active ticket provider (convenience)
final activeTicketProvider = Provider<Ticket?>((ref) {
  return ref.watch(ticketProvider).activeTicket;
});

/// Ticket history provider
final ticketHistoryProvider = Provider<List<Ticket>>((ref) {
  return ref.watch(ticketProvider).history;
});
