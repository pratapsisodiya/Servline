import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/models/location.dart';
import 'package:servline/providers/admin_provider.dart';

class VenueFormScreen extends ConsumerStatefulWidget {
  final LocationModel? location;

  const VenueFormScreen({super.key, this.location});

  @override
  ConsumerState<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends ConsumerState<VenueFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _branchCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  late LocationType _type;
  late bool _isOpen;
  late bool _hasPriority;
  late bool _supportsAppointments;

  bool get _isEditing => widget.location != null;

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    _nameCtrl = TextEditingController(text: loc?.name ?? '');
    _branchCtrl = TextEditingController(text: loc?.branchName ?? '');
    _addressCtrl = TextEditingController(text: loc?.address ?? '');
    _phoneCtrl = TextEditingController(text: loc?.phone ?? '');
    _latCtrl = TextEditingController(text: loc?.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: loc?.longitude?.toString() ?? '');
    _type = loc?.type ?? LocationType.other;
    _isOpen = loc?.isOpen ?? true;
    _hasPriority = loc?.hasPriorityQueue ?? false;
    _supportsAppointments = loc?.supportsAppointments ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _branchCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final location = LocationModel(
      id: widget.location?.id ?? '',
      name: _nameCtrl.text.trim(),
      branchName: _branchCtrl.text.trim().isEmpty ? null : _branchCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text),
      longitude: double.tryParse(_lngCtrl.text),
      type: _type,
      isOpen: _isOpen,
      hasPriorityQueue: _hasPriority,
      supportsAppointments: _supportsAppointments,
      distance: '0 km',
      waitTimeMinutes: 0,
    );

    bool ok;
    if (_isEditing) {
      ok = await ref.read(adminProvider.notifier).updateVenue(location);
    } else {
      ok = await ref.read(adminProvider.notifier).createVenue(location);
    }

    if (ok && mounted) context.pop();
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
        title: Text(
          _isEditing ? 'Edit Venue' : 'New Venue',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: adminState.isLoading ? null : _save,
            child: adminState.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (adminState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      adminState.error!,
                      style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _sectionLabel('Venue Details'),
                const SizedBox(height: 12),
                _textField(
                  ctrl: _nameCtrl,
                  label: 'Venue Name *',
                  hint: 'e.g. City General Hospital',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _textField(
                  ctrl: _branchCtrl,
                  label: 'Branch / Department',
                  hint: 'e.g. OPD Branch, Main Branch',
                ),
                const SizedBox(height: 12),
                _textField(
                  ctrl: _addressCtrl,
                  label: 'Address *',
                  hint: 'Street, City',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _textField(
                  ctrl: _phoneCtrl,
                  label: 'Phone Number',
                  hint: '+1 234 567 8900',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),
                _sectionLabel('Venue Type'),
                const SizedBox(height: 12),
                _typeDropdown(),

                const SizedBox(height: 24),
                _sectionLabel('Location (optional)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        ctrl: _latCtrl,
                        label: 'Latitude',
                        hint: '12.9716',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v!.isEmpty) return null;
                          return double.tryParse(v) != null ? null : 'Invalid';
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        ctrl: _lngCtrl,
                        label: 'Longitude',
                        hint: '77.5946',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v!.isEmpty) return null;
                          return double.tryParse(v) != null ? null : 'Invalid';
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _sectionLabel('Settings'),
                const SizedBox(height: 8),
                _switchTile(
                  title: 'Open',
                  subtitle: 'Venue is visible to customers',
                  value: _isOpen,
                  onChanged: (v) => setState(() => _isOpen = v),
                ),
                _switchTile(
                  title: 'Priority Queue',
                  subtitle: 'Supports priority/VIP queue',
                  value: _hasPriority,
                  onChanged: (v) => setState(() => _hasPriority = v),
                ),
                _switchTile(
                  title: 'Appointments',
                  subtitle: 'Customers can book appointments',
                  value: _supportsAppointments,
                  onChanged: (v) => setState(() => _supportsAppointments = v),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: adminState.isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Create Venue',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      );

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true,
        fillColor: Colors.white,
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
      ),
    );
  }

  Widget _typeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LocationType>(
          value: _type,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: Color(0xFF94A3B8)),
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
          items: LocationType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  Icon(t.icon, size: 18, color: t.color),
                  const SizedBox(width: 10),
                  Text(t.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF7C3AED),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}
