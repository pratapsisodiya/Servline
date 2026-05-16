import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:servline/models/ticket.dart';
import 'package:servline/providers/ticket_provider.dart';
import 'package:servline/widgets/empty_queue_animation.dart';

class VisitHistoryScreen extends ConsumerStatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  ConsumerState<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends ConsumerState<VisitHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load history on init
    Future.microtask(() {
      ref.read(ticketProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
    final historyItems = ticketState.history;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Visit History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
            onPressed: () => ref.read(ticketProvider.notifier).loadHistory(),
          ),
        ],
      ),
      body: ticketState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyItems.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: historyItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final ticket = historyItems[index];
                return _buildHistoryCard(ticket);
              },
            ),
    );
  }

  Widget _buildHistoryCard(Ticket ticket) {
    final isCompleted = ticket.status == TicketStatus.completed;
    final isCancelled = ticket.status == TicketStatus.cancelled;
    final isNoShow = ticket.status == TicketStatus.noShow;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isCompleted) {
      statusColor = const Color(0xFF10B981); // Green
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (isCancelled) {
      statusColor = const Color(0xFFEF4444); // Red
      statusIcon = Icons.cancel;
      statusText = 'Cancelled';
    } else if (isNoShow) {
      statusColor = Colors.orange;
      statusIcon = Icons.timelapse;
      statusText = 'No Show';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.access_time;
      statusText = ticket.status.displayName;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons
                  .local_hospital, // Fallback icon or map from service type if available
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        ticket.locationName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(ticket.issuedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.serviceName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Slate-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ticket.tokenNumber,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyQueueAnimation(
            size: 220,
            message: 'No Visit History',
          ),
          const SizedBox(height: 16),
          Text(
            'Your past visits will appear here.',
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
