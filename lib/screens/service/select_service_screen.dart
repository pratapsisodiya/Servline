import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servline/core/theme/app_theme.dart';
import 'package:servline/providers/location_provider.dart';
import 'package:servline/providers/ticket_provider.dart';
import 'package:servline/widgets/app_button.dart';
import 'package:servline/widgets/loading_overlay.dart';
import 'package:servline/widgets/service_tile.dart';

/// Select Service Screen - as per design screenshot
class SelectServiceScreen extends ConsumerStatefulWidget {
  final String locationId;

  const SelectServiceScreen({super.key, required this.locationId});

  @override
  ConsumerState<SelectServiceScreen> createState() =>
      _SelectServiceScreenState();
}

class _SelectServiceScreenState extends ConsumerState<SelectServiceScreen> {
  int _headCount = 1;

  void _incrementHeadCount() {
    if (_headCount < 10) {
      setState(() => _headCount++);
    }
  }

  void _decrementHeadCount() {
    if (_headCount > 1) {
      setState(() => _headCount--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final ticketState = ref.watch(ticketProvider);
    final services = ref.watch(locationServicesProvider);
    final location = locationState.selectedLocation;

    return LoadingOverlay(
      isLoading: ticketState.isLoading,
      message: 'Joining queue...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Select Service',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.surface,
              child: Column(
                children: [
                  Text(
                    'How can we help you today?',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (location != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        location.branchName ?? location.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Party Size Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Party Size',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            _buildCounterButton(
                              icon: Icons.remove,
                              onPressed: _decrementHeadCount,
                              isEnabled: _headCount > 1,
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$_headCount',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _buildCounterButton(
                              icon: Icons.add,
                              onPressed: _incrementHeadCount,
                              isEnabled: _headCount < 10,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Services List
            Expanded(
              child: locationState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ServiceTile(
                          service: service,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        margin: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Choose Option',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AppButton(
                                      text: 'Join Queue Now',
                                      icon: Icons.run_circle_outlined,
                                      onPressed: () async {
                                        Navigator.pop(context); // Close sheet
                                        final success = await ref
                                            .read(ticketProvider.notifier)
                                            .joinQueue(
                                              locationId:
                                                  location?.id ??
                                                  widget.locationId,
                                              locationName:
                                                  location?.name ?? 'Location',
                                              serviceId: service.id,
                                              serviceName: service.name,
                                              headCount: _headCount,
                                            );

                                        if (success && context.mounted) {
                                          context.go('/active-ticket');
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close sheet
                                        context.push(
                                          '/schedule-appointment/${location?.id ?? widget.locationId}/${location?.name ?? 'Location'}/${service.id}/${service.name}',
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Book for Later',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Bottom Help Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppShadows.bottomNav,
              ),
              child: SafeArea(
                top: false,
                child: AppTextButton(
                  text: 'Need help?',
                  icon: Icons.help_outline,
                  onPressed: () => context.push('/help'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isEnabled,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.primary : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: isEnabled ? onPressed : null,
      ),
    );
  }
}
