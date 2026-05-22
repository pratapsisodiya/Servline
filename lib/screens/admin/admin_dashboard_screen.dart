import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/models/location.dart';
import 'package:servline/providers/admin_provider.dart';
import 'package:servline/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadVenues());
  }

  Future<void> _confirmDelete(LocationModel venue) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Venue', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Delete "${venue.name}"? This cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(adminProvider.notifier).deleteVenue(venue.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                fontSize: 18,
              ),
            ),
            Text(
              '${adminState.venues.length} venue${adminState.venues.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: () => ref.read(adminProvider.notifier).loadVenues(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              ref.read(authProvider.notifier).logout().then((_) {
                if (mounted) context.go('/login');
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/venue/new'),
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Venue',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: adminState.isLoading && adminState.venues.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : adminState.error != null
              ? _buildError(adminState.error!)
              : adminState.venues.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(adminProvider.notifier).loadVenues(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: adminState.venues.length,
                        itemBuilder: (_, i) => _VenueTile(
                          venue: adminState.venues[i],
                          onEdit: () => context.push(
                            '/admin/venue/${adminState.venues[i].id}/edit',
                            extra: adminState.venues[i],
                          ),
                          onQr: () => context.push(
                            '/admin/venue/${adminState.venues[i].id}/qr',
                            extra: adminState.venues[i],
                          ),
                          onServices: () => context.push(
                            '/admin/venue/${adminState.venues[i].id}/services',
                            extra: adminState.venues[i],
                          ),
                          onOperate: () => context.push(
                            '/admin/venue/${adminState.venues[i].id}/operate',
                            extra: adminState.venues[i],
                          ),
                          onDelete: () => _confirmDelete(adminState.venues[i]),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError(String error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(error, style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(adminProvider.notifier).loadVenues(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'No venues yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + New Venue to add your first venue.',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
}

class _VenueTile extends StatelessWidget {
  final LocationModel venue;
  final VoidCallback onEdit;
  final VoidCallback onQr;
  final VoidCallback onServices;
  final VoidCallback onOperate;
  final VoidCallback onDelete;

  const _VenueTile({
    required this.venue,
    required this.onEdit,
    required this.onQr,
    required this.onServices,
    required this.onOperate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: venue.type.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(venue.type.icon, color: venue.type.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (venue.branchName != null)
                        Text(
                          venue.branchName!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      Text(
                        venue.address,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: venue.isOpen
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    venue.isOpen ? 'Open' : 'Closed',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: venue.isOpen
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    _ActionButton(icon: Icons.play_circle_outline_rounded, label: 'Operate', onTap: onOperate, color: const Color(0xFF16A34A)),
                    _ActionButton(icon: Icons.qr_code_rounded, label: 'QR Code', onTap: onQr),
                    _ActionButton(icon: Icons.list_alt_rounded, label: 'Services', onTap: onServices),
                  ],
                ),
                Row(
                  children: [
                    _ActionButton(icon: Icons.edit_outlined, label: 'Edit', onTap: onEdit),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: onDelete,
                      color: const Color(0xFFEF4444),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
