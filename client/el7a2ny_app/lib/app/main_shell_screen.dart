import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../pages/tabs/community_tab_page.dart';
import '../pages/tabs/home_tab_page.dart';
import '../pages/tabs/istighatha_tab_page.dart';
import '../pages/tabs/profile_tab_page.dart';
import '../core/localization/app_strings.dart';
import '../pages/settings_screen.dart';
import '../widgets/language_toggle_button.dart';
import '../services/session_service.dart';
import '../pages/admin_screen.dart';
import '../pages/notifications_page.dart';
import '../widgets/global_fab_overlay.dart';
import '../widgets/artboard_logo.dart';
import '../services/api_service.dart';
import '../core/auth/auth_token_store.dart';
import '../pages/banned_screen.dart';

/// الهيكل الموحد: هيدر ثابت + محتوى + شريط تنقل سفلي.
/// لا يُستخدم مع شاشات تسجيل الدخول / إنشاء الحساب.
class MainShellScreen extends StatefulWidget {
  static final GlobalKey<_MainShellScreenState> shellKey = GlobalKey<_MainShellScreenState>();
  
  MainShellScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key ?? shellKey);

  static void setIndex(BuildContext context, int index) {
    shellKey.currentState?._updateIndex(index);
  }

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
    _checkUserBanStatus();
  }

  Future<void> _checkUserBanStatus() async {
    final userId = AuthTokenStore.userId;
    if (userId == null || userId == 'guest' || userId.isEmpty) {
      return;
    }
    try {
      final user = await ApiService.fetchUserProfile(userId);
      if (user.status == 'banned' && user.bannedUntil != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BannedScreen(bannedUntil: user.bannedUntil!),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking user ban status in MainShellScreen: $e');
    }
  }

  void _updateIndex(int newIndex) {
    if (mounted) {
      setState(() => _index = newIndex);
    }
  }

  Widget _buildRoleToggle(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;
    final isVolunteer = SessionService().currentRole == UserRole.volunteer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isVolunteer 
              ? (isAr ? 'متطوع' : 'Volunteer') 
              : (isAr ? 'مستخدم' : 'User'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansArabic',
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            SessionService().setRole(isVolunteer ? UserRole.citizen : UserRole.volunteer);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 36,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isVolunteer 
                  ? theme.primaryColor 
                  : theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: isVolunteer ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
        navigator.pushNamedAndRemoveUntil(
          '/landing',
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
    final loc = context.loc;

    return ListenableBuilder(
      listenable: SessionService(),
      builder: (context, _) {
        final isAdmin = SessionService().isAdmin;

        final List<Widget> tabs = [
          const HomeTabPage(),
          IstighathaTabPage(onProfileTap: () => _updateIndex(3)),
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
        final isAr = loc.isAr;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isAdmin && safeIndex == 4) {
            GlobalFabController.isAdminScreenActive = true;
            GlobalFabController.hide();
          } else {
            GlobalFabController.isAdminScreenActive = false;
            GlobalFabController.show();
          }
        });

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: (isAdmin && safeIndex == 4) 
              ? Text(loc.adminDashboard, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'NotoSansArabic'))
              : (safeIndex != 0
                  ? const ArtboardLogo(size: 80)
                  : null),
            centerTitle: true,
            leadingWidth: isAr ? (safeIndex != 0 ? 135 : 110) : (safeIndex != 0 ? 40 : null),
            leading: isAr
                ? (safeIndex != 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
                            onPressed: () => setState(() => _index = 0),
                          ),
                          const SizedBox(width: 4),
                          _buildRoleToggle(context),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Center(child: _buildRoleToggle(context)),
                      ))
                : (safeIndex != 0
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
                        onPressed: () => setState(() => _index = 0),
                      )
                    : null),
            actions: [
              if (!isAr) ...[
                _buildRoleToggle(context),
                const SizedBox(width: 8),
              ],
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
                icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface, size: 22),
              ),
              const SizedBox(width: 4),
              LanguageToggleButton(iconColor: theme.colorScheme.onSurface),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface, size: 22),
                ),
              ),
              const SizedBox(width: 6),
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
      },
    );
  }
}
