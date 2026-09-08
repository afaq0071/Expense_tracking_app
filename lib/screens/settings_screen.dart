import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/fade_slide_in.dart';
import 'notification_settings_screen.dart';
import 'export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: StaggeredAnimation(
          staggerDelay: const Duration(milliseconds: 60),
          children: [
            _buildProfileCard(displayName, email),
            const SizedBox(height: 24),
            _buildSectionHeader('General'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildTile(
                icon: Icons.language_rounded,
                iconBg: AppColors.primaryLight,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
              _buildDivider(),
              _buildTile(
                icon: Icons.dark_mode_outlined,
                iconBg: const Color(0xFF6366F1),
                title: 'Appearance',
                subtitle: 'System default',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Notifications'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildTile(
                icon: Icons.notifications_outlined,
                iconBg: AppColors.secondary,
                title: 'Notification Settings',
                subtitle: 'Budget alerts, reminders',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Data'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildTile(
                icon: Icons.file_download_outlined,
                iconBg: const Color(0xFF0EA5E9),
                title: 'Export Data',
                subtitle: 'Download CSV / JSON',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExportScreen(
                      expenses: [],
                      wallets: [],
                    ),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Support'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildTile(
                icon: Icons.help_outline_rounded,
                iconBg: const Color(0xFFF59E0B),
                title: 'Help & FAQ',
                subtitle: 'Get answers to common questions',
                onTap: () {},
              ),
              _buildDivider(),
              _buildTile(
                icon: Icons.feedback_outlined,
                iconBg: const Color(0xFFEC4899),
                title: 'Send Feedback',
                subtitle: 'Help us improve the app',
                onTap: () {},
              ),
              _buildDivider(),
              _buildTile(
                icon: Icons.info_outline_rounded,
                iconBg: AppColors.textSecondary,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Account'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _buildTile(
                icon: Icons.logout_rounded,
                iconBg: AppColors.expense,
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                iconColor: AppColors.expense,
                titleColor: AppColors.expense,
                onTap: () => _confirmLogout(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? iconBg,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 72,
      color: AppColors.inputBorder.withValues(alpha: 0.5),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Log Out',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (_) => false,
                );
              }
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.poppins(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
