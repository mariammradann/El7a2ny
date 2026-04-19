import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/locale_provider.dart';
import '../widgets/language_toggle_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'verify_password_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _notifications = status.isGranted;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showSettingsDialog();
      }
      setState(() => _notifications = status.isGranted);
    } else {
      // Typically we don't "revoke" via code, but we can mute app logic.
      // For a "real" feel, we'll just update state and maybe show a snackbar.
      setState(() => _notifications = false);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.notifications),
        content: const Text('Please enable notifications in system settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.okBtn),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            context.loc.settings,
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.primaryColor,
            ),
          ),
          actions: const [
            LanguageToggleButton(),
            SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildSectionHeader(context, context.loc.account),
              _buildTile(
                context,
                icon: Icons.person_outline_rounded,
                title: context.loc.editProfile,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.comingSoon)));
                },
              ),
              _buildTile(
                context,
                icon: Icons.lock_outline_rounded,
                title: context.loc.changePassword,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const VerifyCurrentPasswordScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, context.loc.preferences),
              _buildSwitchTile(
                context,
                icon: Icons.dark_mode_outlined,
                title: context.loc.darkMode,
                value: AppConfigProvider.of(context).isDarkMode,
                onChanged: (v) {
                  AppConfigProvider.of(context).toggleTheme();
                },
              ),
              _buildSwitchTile(
                context,
                icon: Icons.notifications_active_outlined,
                title: context.loc.notifications,
                value: _notifications,
                onChanged: _toggleNotifications,
              ),
              _buildTile(
                context,
                icon: Icons.language_rounded,
                title: context.loc.language,
                trailing: Text(
                  context.loc.isAr ? 'العربية' : 'English',
                  style: TextStyle(fontFamily: 'NotoSansArabic', color: colorScheme.onSurface.withOpacity(0.6)),
                ),
                onTap: () {
                  AppConfigProvider.of(context).toggleLanguage();
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, context.loc.helpAndSupport),
              _buildTile(
                context,
                icon: Icons.help_outline_rounded,
                title: context.loc.helpCenter,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.comingSoon)));
                },
              ),
              _buildTile(
                context,
                icon: Icons.info_outline_rounded,
                title: context.loc.aboutApp,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'El7a2ny App',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(Icons.shield_rounded, color: theme.primaryColor, size: 40),
                    children: [
                      Text(context.loc.aboutAppDesc),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'NotoSansArabic',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: theme.primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: theme.primaryColor,
        secondary: Icon(icon, color: theme.primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
