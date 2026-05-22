import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/models/location.dart';
import 'package:servline/models/service.dart';
import 'package:servline/providers/admin_provider.dart';
import 'package:servline/screens/admin/service_form_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final LocationModel location;

  const ServicesScreen({super.key, required this.location});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminProvider.notifier).loadServices(widget.location.id),
    );
  }

  void _openForm({ServiceModel? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceFormSheet(
        locationId: widget.location.id,
        service: service,
      ),
    );
  }

  Future<void> _confirmDelete(ServiceModel service) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Delete "${service.name}"?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(adminProvider.notifier).deleteService(service.id);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                fontSize: 17,
              ),
            ),
            Text(
              widget.location.name,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF7C3AED),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: adminState.isLoading && adminState.services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : adminState.services.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: adminState.services.length,
                  itemBuilder: (_, i) {
                    final svc = adminState.services[i];
                    return _ServiceTile(
                      service: svc,
                      onEdit: () => _openForm(service: svc),
                      onDelete: () => _confirmDelete(svc),
                      onToggle: (active) {
                        final updated = ServiceModel(
                          id: svc.id,
                          name: svc.name,
                          description: svc.description,
                          locationId: svc.locationId,
                          estimatedWaitMinutes: svc.estimatedWaitMinutes,
                          currentQueueSize: svc.currentQueueSize,
                          icon: svc.icon,
                          isActive: active,
                        );
                        ref.read(adminProvider.notifier).updateService(updated);
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.list_alt_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'No services yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a service to this venue.',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
}

class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  const _ServiceTile({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(service.icon, color: const Color(0xFF64748B), size: 22),
        ),
        title: Text(
          service.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${service.formattedWaitTime} wait${service.description != null ? ' · ${service.description}' : ''}',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: service.isActive,
              onChanged: onToggle,
              activeThumbColor: const Color(0xFF7C3AED),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
