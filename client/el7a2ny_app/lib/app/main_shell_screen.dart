import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../pages/tabs/community_tab_page.dart';
import '../pages/tabs/home_tab_page.dart';
import '../pages/tabs/istighatha_tab_page.dart';
import '../pages/tabs/profile_tab_page.dart';
import '../core/localization/app_strings.dart';
import '../pages/landing_screen.dart';
import '../pages/settings_screen.dart';
import '../widgets/language_toggle_button.dart';
import '../services/session_service.dart';
import '../pages/admin_screen.dart';
import '../pages/notifications_page.dart';

/// الهيكل الموحد: هيدر ثابت + محتوى + شريط تنقل سفلي.
/// لا يُستخدم مع شاشات تسجيل الدخول / إنشاء الحساب.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _index;

  final _auth = AuthRepository();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    // Note: index clamping will happen dynamically in build based on isAdmin
  }

  Future<void> _onMenu(String value) async {
    switch (value) {
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const SettingsScreen(),
          ),
        );
        break;
      case 'logout':
        final navigator = Navigator.of(context);
        await _auth.logout();
        if (!mounted) return;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (context) => const LandingScreen(),
          ),
          (route) => false,
        );
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.help)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = SessionService().isAdmin;
    final loc = context.loc;

    final List<Widget> tabs = [
      const HomeTabPage(),
      const IstighathaTabPage(),
      const CommunityTabPage(),
      const ProfileTabPage(),
      if (isAdmin) const AdminScreen(isNested: true),
    ];

    final List<NavigationDestination> destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded, color: theme.primaryColor),
        label: loc.tabHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.warning_amber_rounded),
        selectedIcon: Icon(Icons.emergency_share_rounded, color: theme.primaryColor),
        label: loc.tabIstighatha,
      ),
      NavigationDestination(
        icon: const Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded, color: theme.primaryColor),
        label: loc.tabCommunity,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded, color: theme.primaryColor),
        label: loc.tabProfile,
      ),
      if (isAdmin)
        NavigationDestination(
          icon: const Icon(Icons.insights_rounded),
          selectedIcon: Icon(Icons.insights_rounded, color: theme.primaryColor),
          label: loc.tabInsights,
        ),
    ];

    // Ensure index doesn't overflow if isAdmin state changes
    final safeIndex = _index.clamp(0, destinations.length - 1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: (isAdmin && safeIndex == 4) 
          ? Text(loc.adminDashboard, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'NotoSansArabic'))
          : null,
        centerTitle: true,
        leading: PopupMenuButton<String>(
          tooltip: context.loc.menu,
          offset: const Offset(0, 48),
          onSelected: _onMenu,
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    context.loc.settings,
                    style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: theme.colorScheme.onSurface, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    context.loc.logout,
                    style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: theme.colorScheme.onSurface, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    context.loc.help,
                    style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          child: Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
            icon: Badge(
              label: const Text('3', style: TextStyle(fontSize: 10)),
              backgroundColor: theme.primaryColor,
              child: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
            ),
          ),
          LanguageToggleButton(iconColor: theme.colorScheme.onSurface),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        sizing: StackFit.expand,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.primaryColor.withValues(alpha: 0.12),
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
