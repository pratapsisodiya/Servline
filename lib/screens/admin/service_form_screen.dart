import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/models/service.dart';
import 'package:servline/providers/admin_provider.dart';

class ServiceFormSheet extends ConsumerStatefulWidget {
  final String locationId;
  final ServiceModel? service;

  const ServiceFormSheet({super.key, required this.locationId, this.service});

  @override
  ConsumerState<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _waitCtrl;
  late IconData _icon;
  late bool _isActive;

  bool get _isEditing => widget.service != null;

  static const _iconOptions = [
    Icons.confirmation_number,
    Icons.account_balance,
    Icons.attach_money,
    Icons.credit_card,
    Icons.health_and_safety,
    Icons.medical_services,
    Icons.support_agent,
    Icons.help_outline,
    Icons.person,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _waitCtrl = TextEditingController(text: s?.estimatedWaitMinutes.toString() ?? '5');
    _icon = s?.icon ?? Icons.confirmation_number;
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _waitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ServiceModel(
      id: widget.service?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      locationId: widget.locationId,
      estimatedWaitMinutes: int.tryParse(_waitCtrl.text) ?? 5,
      icon: _icon,
      isActive: _isActive,
    );

    bool ok;
    if (_isEditing) {
      ok = await ref.read(adminProvider.notifier).updateService(service);
    } else {
      ok = await ref.read(adminProvider.notifier).createService(service);
    }

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Edit Service' : 'New Service',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: _inputDecoration('Service Name *', 'e.g. General Consultation'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: _inputDecoration('Description', 'Short description (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _waitCtrl,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v ?? '') != null ? null : 'Enter a number',
              style: GoogleFonts.inter(fontSize: 14),
              decoration: _inputDecoration('Estimated Wait (minutes)', '5'),
            ),

            const SizedBox(height: 16),
            Text(
              'Icon',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _iconOptions.map((ic) {
                final selected = ic == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = ic),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEDE9FE) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: const Color(0xFF7C3AED), width: 2)
                          : null,
                    ),
                    child: Icon(
                      ic,
                      size: 22,
                      color: selected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Active',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const Spacer(),
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: const Color(0xFF7C3AED),
                ),
              ],
            ),

            if (adminState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                adminState.error!,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFDC2626)),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: adminState.isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: adminState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add Service',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
