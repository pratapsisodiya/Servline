import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:servline/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return settingsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (settings) => Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionHeader('ACCESSIBILITY'),
            _buildSectionContainer([
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Text Size',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(settings.textSize * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'A-',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: settings.textSize,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            activeColor: const Color(0xFF3B82F6),
                            onChanged: (value) {
                              notifier.setTextSize(value);
                            },
                          ),
                        ),
                        Text(
                          'A+',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Adjust the slider to increase/decrease the size of text within the app.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ]),

            _buildSectionHeader('NOTIFICATIONS'),
            _buildSectionContainer([
              _buildSwitchTile(
                icon: Icons.notifications_active,
                iconColor: Colors.blue,
                title: 'Notification Sounds',
                value: settings.notificationSounds,
                onChanged: (v) => notifier.toggleNotificationSounds(v),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(height: 1),
              ),
              _buildSwitchTile(
                icon: Icons.vibration,
                iconColor: Colors.purple,
                title: 'Vibration',
                value: settings.vibration,
                onChanged: (v) => notifier.toggleVibration(v),
              ),
            ]),

            _buildSectionHeader('GENERAL'),
            _buildSectionContainer([
              _buildNavTile(
                icon: Icons.language,
                iconColor: Colors.orange,
                title: 'Language',
                trailing: Text(
                  'English >',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
                onTap: () {},
              ),
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(height: 1),
              ),
              _buildSwitchTile(
                icon: Icons.dark_mode,
                iconColor: Colors.black,
                title: 'Dark Mode',
                value: settings.darkMode,
                onChanged: (v) => notifier.toggleDarkMode(v),
              ),
            ]),

            _buildSectionHeader('SUPPORT'),
            _buildSectionContainer([
              _buildNavTile(
                icon: Icons.help_outline,
                iconColor: Colors.green,
                title: 'Help Center',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.push('/help'),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(height: 1),
              ),
              _buildNavTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.grey,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 48),
            Text(
              'Servline v1.0.0 (34)',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: const Color(0xFF3B82F6),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: trailing,
    );
  }
}
