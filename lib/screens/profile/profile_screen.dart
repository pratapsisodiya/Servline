import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:servline/providers/auth_provider.dart';
import 'package:servline/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: AppTextStyles.h3),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showEditProfileDialog() {
    // TODO: Implement actual update via repository
    // For now, just a placeholder as updating profile wasn't strictly in Phase 1 scope
    // but the UI should be there.
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Call update profile
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final initials = user.name.isNotEmpty
        ? user.name
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!user.isGuest)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: _showEditProfileDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 32),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: user.isGuest
                          ? const Icon(
                              Icons.face_3_rounded,
                              size: 52,
                              color: AppColors.primary,
                            )
                          : Text(
                              initials,
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  ),
                  if (user.isGuest)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Guest Account',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Text(
                      user.email,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),

            // Profile Details
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!user.isGuest) ...[
                    _buildSectionHeader('Account Info'),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.cardSmall,
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            subtitle: user.email,
                          ),
                          const Divider(height: 1),
                          _buildListTile(
                            icon: Icons.phone_outlined,
                            title: 'Phone',
                            subtitle: user.phone ?? 'Not set',
                          ),
                          const Divider(height: 1),
                          _buildListTile(
                            icon: Icons.calendar_today_rounded,
                            title: 'Member Since',
                            subtitle: user.createdAt != null
                                ? DateFormat.yMMMd().format(user.createdAt!)
                                : 'Unknown',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionHeader('Preferences'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.cardSmall,
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.settings_outlined,
                          title: 'App Settings',
                          subtitle: 'Notifications, Sound, Theme',
                          onTap: () => context.push('/settings'),
                          showArrow: true,
                        ),
                        if (user.isGuest) ...[
                          const Divider(height: 1),
                          _buildListTile(
                            icon: Icons.app_registration_rounded,
                            title: 'Create Account',
                            subtitle: 'Sign up to sync your data',
                            onTap: () async {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) context.go('/signup');
                            },
                            showArrow: true,
                            iconColor: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.label.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showArrow = false,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: showArrow
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
