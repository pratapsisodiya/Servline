import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/models/location.dart';
import 'package:servline/models/service.dart';
import 'package:servline/models/ticket.dart';
import 'package:servline/repositories/location_repository.dart';
import 'package:servline/repositories/queue_operator_repository.dart';

class QueueOperatorScreen extends ConsumerStatefulWidget {
  final LocationModel location;

  const QueueOperatorScreen({super.key, required this.location});

  @override
  ConsumerState<QueueOperatorScreen> createState() => _QueueOperatorScreenState();
}

class _QueueOperatorScreenState extends ConsumerState<QueueOperatorScreen> {
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _error;
  String _counterNumber = '1';
  RealtimeSubscription? _subscription;

  List<Ticket> get _waiting => (_tickets.where((t) => t.status == TicketStatus.waiting).toList()
    ..sort((a, b) => a.currentQueuePosition.compareTo(b.currentQueuePosition)));

  List<Ticket> get _called => _tickets
      .where((t) => t.status == TicketStatus.called || t.status == TicketStatus.serving)
      .toList();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final locRepo = ref.read(locationRepositoryProvider);
      final services = await locRepo.getAllLocationServices(widget.location.id);
      if (!mounted) return;
      setState(() {
        _services = services;
        _selectedService = services.isNotEmpty ? services.first : null;
        _isLoading = false;
      });
      if (_selectedService != null) await _loadTickets();
      _subscribeToQueue();
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadTickets() async {
    final svc = _selectedService;
    if (svc == null) return;
    try {
      final repo = ref.read(queueOperatorRepositoryProvider);
      final tickets = await repo.getActiveTickets(
        locationId: widget.location.id,
        serviceId: svc.id,
      );
      if (mounted) setState(() { _tickets = tickets; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _subscribeToQueue() {
    _subscription?.close();
    final repo = ref.read(queueOperatorRepositoryProvider);
    _subscription = repo.subscribeToQueue(() {
      if (mounted) _loadTickets();
    });
  }

  Future<void> _selectService(ServiceModel svc) async {
    setState(() { _selectedService = svc; _tickets = []; _isLoading = true; });
    await _loadTickets();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _callNext() async {
    final svc = _selectedService;
    if (svc == null || _waiting.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(queueOperatorRepositoryProvider);
      await repo.callNext(
        locationId: widget.location.id,
        serviceId: svc.id,
        counterNumber: _counterNumber,
      );
      await _loadTickets();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _serve(String ticketId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(queueOperatorRepositoryProvider).serveTicket(ticketId);
      await _loadTickets();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _noShow(String ticketId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(queueOperatorRepositoryProvider).noShowTicket(ticketId);
      await _loadTickets();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _returnToQueue(Ticket ticket) async {
    final svc = _selectedService;
    if (svc == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(queueOperatorRepositoryProvider).returnToQueue(
        ticket: ticket,
        locationId: widget.location.id,
        serviceId: svc.id,
      );
      await _loadTickets();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
              'Queue Operator',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                fontSize: 17,
              ),
            ),
            Text(
              widget.location.name,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          _CounterSelector(
            current: _counterNumber,
            onChanged: (v) => setState(() => _counterNumber = v),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: () { setState(() => _isLoading = true); _loadTickets().then((_) { if (mounted) setState(() => _isLoading = false); }); },
          ),
        ],
      ),
      body: _isLoading && _tickets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_services.isNotEmpty)
                  _ServiceTabs(
                    services: _services,
                    selected: _selectedService,
                    onSelect: _selectService,
                  ),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                Expanded(
                  child: _selectedService == null
                      ? _buildNoServices()
                      : _buildBody(),
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsRow(waiting: _waiting.length, called: _called.length),
        const SizedBox(height: 16),

        if (_called.isNotEmpty) ...[
          _sectionLabel('Now Serving'),
          const SizedBox(height: 8),
          ..._called.map((t) => _CalledTicketCard(
                ticket: t,
                counterNumber: _counterNumber,
                onServed: () => _serve(t.id),
                onNoShow: () => _noShow(t.id),
                onReturn: () => _returnToQueue(t),
              )),
          const SizedBox(height: 16),
        ],

        _CallNextButton(
          hasWaiting: _waiting.isNotEmpty,
          isLoading: _isLoading,
          onTap: _callNext,
        ),
        const SizedBox(height: 20),

        if (_waiting.isNotEmpty) ...[
          _sectionLabel('Waiting (${_waiting.length})'),
          const SizedBox(height: 8),
          ..._waiting.map((t) => _WaitingTicketCard(ticket: t)),
        ] else
          _buildEmptyQueue(),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      );

  Widget _buildNoServices() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.list_alt_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text('No services added yet',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Add services to this venue first.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ],
        ),
      );

  Widget _buildEmptyQueue() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF22C55E)),
          const SizedBox(height: 12),
          Text('Queue is clear',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
          Text('No one is waiting right now.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
        ]),
      );
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _ServiceTabs extends StatelessWidget {
  final List<ServiceModel> services;
  final ServiceModel? selected;
  final void Function(ServiceModel) onSelect;

  const _ServiceTabs({required this.services, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: services.map((svc) {
            final active = svc.id == selected?.id;
            return GestureDetector(
              onTap: () => onSelect(svc),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  svc.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int waiting;
  final int called;
  const _StatsRow({required this.waiting, required this.called});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Waiting', value: waiting, color: const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Now Serving', value: called, color: const Color(0xFF22C55E))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text('$value',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
      ]),
    );
  }
}

class _CallNextButton extends StatelessWidget {
  final bool hasWaiting;
  final bool isLoading;
  final VoidCallback onTap;
  const _CallNextButton({required this.hasWaiting, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: hasWaiting && !isLoading ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD1FAE5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.arrow_forward_rounded, size: 22),
        label: Text(
          hasWaiting ? 'Call Next Patient' : 'No One Waiting',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

class _CalledTicketCard extends StatelessWidget {
  final Ticket ticket;
  final String counterNumber;
  final VoidCallback onServed;
  final VoidCallback onNoShow;
  final VoidCallback onReturn;

  const _CalledTicketCard({
    required this.ticket,
    required this.counterNumber,
    required this.onServed,
    required this.onNoShow,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(ticket.tokenNumber,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ticket.serviceName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
                if (ticket.headCount > 1)
                  Text('Party of ${ticket.headCount}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text('Counter ${ticket.counterNumber ?? counterNumber}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(flex: 2, child: _Btn(label: 'Served ✓', bg: Colors.white, fg: const Color(0xFF16A34A), onTap: onServed)),
            const SizedBox(width: 8),
            Expanded(child: _Btn(label: 'No Show', bg: Colors.white.withValues(alpha: 0.2), fg: Colors.white, onTap: onNoShow)),
            const SizedBox(width: 8),
            Expanded(child: _Btn(label: 'Return', bg: Colors.white.withValues(alpha: 0.2), fg: Colors.white, onTap: onReturn)),
          ]),
        ]),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: fg))),
      ),
    );
  }
}

class _WaitingTicketCard extends StatelessWidget {
  final Ticket ticket;
  const _WaitingTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('#${ticket.currentQueuePosition}',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ticket.tokenNumber,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
          Text(
            ticket.headCount > 1
                ? 'Party of ${ticket.headCount} · ~${ticket.estimatedWaitMinutes} min'
                : '~${ticket.estimatedWaitMinutes} min wait',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
        ])),
        Text(_timeAgo(ticket.issuedAt),
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _CounterSelector extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;
  const _CounterSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Counter $current',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
      ),
    );
  }

  void _pick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Counter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: List.generate(6, (i) {
              final n = '${i + 1}';
              final sel = n == current;
              return GestureDetector(
                onTap: () { onChanged(n); Navigator.pop(context); },
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(n,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18,
                          color: sel ? Colors.white : const Color(0xFF1E293B)))),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
