import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/locale_provider.dart';
import '../widgets/language_toggle_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'verify_password_screen.dart';

const Color _kBrandRed = Color(0xFFE44646);
const Color _kTextDark = Color(0xFF424242);
const Color _kBgWhite = Colors.white;
const Color _kSectionBg = Color(0xFFF9F9F9);

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
    return Scaffold(
      backgroundColor: _kBgWhite,
        appBar: AppBar(
          backgroundColor: _kBgWhite,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            context.loc.settings,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kBrandRed,
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
              _buildSectionHeader(context.loc.account),
              _buildTile(
                icon: Icons.person_outline_rounded,
                title: context.loc.editProfile,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.comingSoon)));
                },
              ),
              _buildTile(
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
              _buildSectionHeader(context.loc.preferences),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: context.loc.darkMode,
                value: AppConfigProvider.of(context).isDarkMode,
                onChanged: (v) {
                  AppConfigProvider.of(context).toggleTheme();
                },
              ),
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: context.loc.notifications,
                value: _notifications,
                onChanged: _toggleNotifications,
              ),
              _buildTile(
                icon: Icons.language_rounded,
                title: context.loc.language,
                trailing: Text(
                  context.loc.isAr ? 'العربية' : 'English',
                  style: TextStyle(fontFamily: 'NotoSansArabic', color: Colors.grey.shade600),
                ),
                onTap: () {
                  AppConfigProvider.of(context).toggleLanguage();
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context.loc.helpAndSupport),
              _buildTile(
                icon: Icons.help_outline_rounded,
                title: context.loc.helpCenter,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.comingSoon)));
                },
              ),
              _buildTile(
                icon: Icons.info_outline_rounded,
                title: context.loc.aboutApp,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'El7a2ny App',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.shield_rounded, color: _kBrandRed, size: 40),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'NotoSansArabic',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSectionBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: _kBrandRed),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSectionBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: _kBrandRed,
        secondary: Icon(icon, color: _kBrandRed),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
