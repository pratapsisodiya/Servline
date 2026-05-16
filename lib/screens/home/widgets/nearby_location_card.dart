import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/models/location.dart';

class NearbyLocationCard extends StatefulWidget {
  final LocationModel location;

  const NearbyLocationCard({super.key, required this.location});

  @override
  State<NearbyLocationCard> createState() => _NearbyLocationCardState();
}

class _NearbyLocationCardState extends State<NearbyLocationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                  : const Color(0xFFF1F5F9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: _isPressed ? 20 : 10,
                offset: Offset(0, _isPressed ? 8 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Premium Location Icon with gradient
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.location.type.backgroundColor,
                      widget.location.type.color.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.location.type.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.location.type.icon,
                  color: widget.location.type.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Location info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.location.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${widget.location.distance} • ${widget.location.type.displayName}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Feature badges
                    Row(
                      children: [
                        if (widget.location.hasPriorityQueue)
                          _buildFeatureBadge(
                            Icons.accessibility_new,
                            'Priority',
                            const Color(0xFF8B5CF6),
                          ),
                        if (widget.location.supportsAppointments) ...[
                          if (widget.location.hasPriorityQueue)
                            const SizedBox(width: 6),
                          _buildFeatureBadge(
                            Icons.event_available,
                            'Appointments',
                            const Color(0xFF3B82F6),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Premium wait time indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getWaitTimeColor(widget.location.waitTimeMinutes),
                          _getWaitTimeColor(widget.location.waitTimeMinutes)
                              .withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _getWaitTimeTextColor(
                                  widget.location.waitTimeMinutes)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _getWaitTimeText(widget.location.waitTimeMinutes),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getWaitTimeTextColor(
                            widget.location.waitTimeMinutes),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.location.waitTimeMinutes}m',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getWaitTimeColor(int minutes) {
    if (minutes < 10) return const Color(0xFFD1FAE5); // Green-100
    if (minutes < 30) return const Color(0xFFFEF3C7); // Amber-100
    return const Color(0xFFFECDD3); // Red-100
  }

  Color _getWaitTimeTextColor(int minutes) {
    if (minutes < 10) return const Color(0xFF059669); // Green-600
    if (minutes < 30) return const Color(0xFFD97706); // Amber-600
    return const Color(0xFFDC2626); // Red-600
  }

  String _getWaitTimeText(int minutes) {
    if (minutes < 10) return 'SHORT';
    if (minutes < 30) return 'MEDIUM';
    return 'LONG';
  }
}
