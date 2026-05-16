import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/models/location.dart';

class NearbyLocationCard extends StatelessWidget {
  final LocationModel location;

  const NearbyLocationCard({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000), // 4% black
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Location type icon
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: location.type.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              location.type.icon,
              color: location.type.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Location info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${location.distance} • ${location.type.displayName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (location.hasPriorityQueue) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.accessibility_new,
                        size: 14,
                        color: Color(0xFF8B5CF6),
                      ),
                    ],
                    if (location.supportsAppointments) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Wait time badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getWaitTimeColor(location.waitTimeMinutes),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getWaitTimeText(location.waitTimeMinutes),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getWaitTimeTextColor(location.waitTimeMinutes),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(${location.waitTimeMinutes}m)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Color _getWaitTimeColor(int minutes) {
    if (minutes < 10) return const Color(0xFFDCFCE7); // Green-100
    if (minutes < 30) return const Color(0xFFFEF3C7); // Amber-100
    return const Color(0xFFFEE2E2); // Red-100
  }

  Color _getWaitTimeTextColor(int minutes) {
    if (minutes < 10) return const Color(0xFF22C55E); // Green
    if (minutes < 30) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  String _getWaitTimeText(int minutes) {
    if (minutes < 10) return 'Short Wait';
    if (minutes < 30) return 'Medium Wait';
    return 'Long Wait';
  }
}
