import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../pages/tabs/community_tab_page.dart';
import '../pages/tabs/home_tab_page.dart';
import '../pages/tabs/istighatha_tab_page.dart';
import '../pages/tabs/profile_tab_page.dart';
import '../pages/welcome_screen.dart';
import '../widgets/emergency_dashboard_widgets.dart';

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
    _index = widget.initialIndex.clamp(0, 3);
  }

  Future<void> _onMenu(String value) async {
    switch (value) {
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الإعدادات — قريباً')),
        );
        break;
      case 'logout':
        final navigator = Navigator.of(context);
        await _auth.logout();
        if (!mounted) return;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (context) => const WelcomeScreen(),
          ),
          (route) => false,
        );
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المساعدة — قريباً')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: emergencyPageBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          // RTL: القائمة يمين، الإشعارات يسار
          leading: PopupMenuButton<String>(
            tooltip: 'القائمة',
            offset: const Offset(0, 48),
            onSelected: _onMenu,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: emergencyTextDark, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'الإعدادات',
                      style: TextStyle(fontFamily: 'Unixel', fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: emergencyTextDark, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'تسجيل الخروج',
                      style: TextStyle(fontFamily: 'Unixel', fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: emergencyTextDark, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'المساعدة',
                      style: TextStyle(fontFamily: 'Unixel', fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.menu_rounded, color: emergencyTextDark),
          ),
          actions: [
            IconButton(
              tooltip: 'الإشعارات',
              icon: Icon(Icons.notifications_outlined, color: emergencyTextDark),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الإشعارات — قريباً')),
                );
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          sizing: StackFit.expand,
          children: const [
            HomeTabPage(),
            IstighathaTabPage(),
            CommunityTabPage(),
            ProfileTabPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 64,
          backgroundColor: Colors.white,
          indicatorColor: emergencyTitleRed.withValues(alpha: 0.12),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_rounded),
              selectedIcon: Icon(Icons.emergency_share_rounded),
              label: 'استغاثة',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Community',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
