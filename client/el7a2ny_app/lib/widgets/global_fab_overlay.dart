import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../models/user_model.dart';
import '../core/auth/auth_token_store.dart';
import '../pages/active_incident_tracking_screen.dart';
import '../pages/emergency_chat_screen.dart';
import '../widgets/language_toggle_button.dart';
import '../core/localization/locale_provider.dart';

class GlobalFabController {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isChatButtonVisible = ValueNotifier<bool>(true);
  static final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  static void show() => isVisible.value = true;
  static void hide() => isVisible.value = false;

  static void showChatButton() => isChatButtonVisible.value = true;
  static void hideChatButton() => isChatButtonVisible.value = false;
}

class GlobalFabOverlay extends StatelessWidget {
  final Widget child;

  const GlobalFabOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: GlobalFabController.isVisible,
          builder: (context, visible, _) {
            if (!visible) return const SizedBox.shrink();

            final isGuest = AuthTokenStore.userId == null || AuthTokenStore.userId == 'guest';
            final isAr = AppConfigProvider.of(context).isArabic;

            return Stack(
              children: [
                // ── Side FABs Column ──
                Positioned(
                  left: isAr ? 16 : null,
                  right: isAr ? null : 16,
                  bottom: 120, // Raised to avoid bottom sheet overlap
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: isAr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        // SOS Button (Always Visible)
                        HoverExpandableFab(
                          label: isAr ? 'بلاغ طوارئ' : 'Emergency Report',
                          icon: Icons.emergency_share_rounded,
                          backgroundColor: theme.colorScheme.error,
                          iconColor: Colors.white,
                          heroTag: 'global_sos_fab',
                          onTap: () async {
                            final navContext = GlobalFabController.navigatorKey.currentContext;
                            if (navContext != null) {
                              ScaffoldMessenger.of(navContext).showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? 'بدء إجراءات الاستغاثة الفورية...' : 'Initiating instant SOS...'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }

                            try {
                              final pos = await Geolocator.getCurrentPosition();
                              await ApiService.sendEmergencyAlert(
                                userId: AuthTokenStore.userId ?? 'guest',
                                type: 'instant_sos_fab',
                                lat: pos.latitude,
                                lng: pos.longitude,
                                description: 'Instant SOS triggered from FAB',
                              );
                            } catch (_) {}

                            UserModel? user;
                            try {
                              user = await ApiService.fetchUserProfile();
                            } catch (_) {}

                            final officials = ['122', '123', '180'];
                            for (var num in officials) {
                              bool? res = await FlutterPhoneDirectCaller.callNumber(num);
                              if (res == true) await Future.delayed(const Duration(seconds: 10));
                            }

                            if (user != null && user.emergencyContacts.isNotEmpty) {
                              for (var contact in user.emergencyContacts) {
                                bool? res = await FlutterPhoneDirectCaller.callNumber(contact.phone);
                                if (res == true) await Future.delayed(const Duration(seconds: 10));
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Return to Active Incident Button
                        // Return to Active Incident Button
                        ListenableBuilder(
                          listenable: SessionService(),
                          builder: (context, _) {
                            return ValueListenableBuilder<String?>(
                              valueListenable: GlobalFabController.currentRoute,
                              builder: (context, currentRoute, _) {
                                final activeId = SessionService().activeIncidentId;
                                if (activeId == null || currentRoute == '/active-incident') return const SizedBox.shrink();
                                return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: HoverExpandableFab(
                                label: isAr ? 'العودة للبلاغ' : 'Active Incident',
                                icon: Icons.location_on_rounded,
                                backgroundColor: Colors.orange.shade700,
                                iconColor: Colors.white,
                                heroTag: 'global_active_incident_fab',
                                onTap: () {
                                  GlobalFabController.navigatorKey.currentState?.push(
                                    MaterialPageRoute(
                                      builder: (context) => ActiveIncidentTrackingScreen(
                                        incidentId: activeId,
                                        initialLat: SessionService().activeIncidentLat ?? 0.0,
                                        initialLng: SessionService().activeIncidentLng ?? 0.0,
                                      ),
                                      settings: const RouteSettings(name: '/active-incident'),
                                    ),
                                  );
                                },
                              ),
                            );
                              },
                            );
                          },
                        ),

                        // Chatbot Button (Always Visible)
                        ValueListenableBuilder<bool>(
                          valueListenable: GlobalFabController.isChatButtonVisible,
                          builder: (context, chatVisible, _) {
                            if (!chatVisible) return const SizedBox.shrink();
                            return HoverExpandableFab(
                              label: isAr ? 'مساعد ذكي' : 'Smart Assistant',
                              icon: Icons.forum_rounded,
                              backgroundColor: isDark ? theme.colorScheme.primaryContainer : const Color(0xFF2D3243),
                              iconColor: isDark ? theme.colorScheme.onPrimaryContainer : Colors.white,
                              heroTag: 'global_chat_fab',
                              onTap: () {
                                GlobalFabController.navigatorKey.currentState?.push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => const EmergencyChatScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Language Toggle at Top ──
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: isAr ? null : 16,
                  left: isAr ? 16 : null,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(25),
                    child: const LanguageToggleButton(iconColor: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),

        // ── Volunteer Active Incident Alert Bar (RED BAR) ──
        ListenableBuilder(
          listenable: SessionService(),
          builder: (context, _) {
            final activeId = SessionService().activeIncidentId;
            final role = SessionService().incidentRole;
            final showRedBar = SessionService().showVolunteerAlert;
            final isAr = AppConfigProvider.of(context).isArabic;
            
            if (activeId == null || role != IncidentRole.volunteer || !showRedBar) return const SizedBox.shrink();
            
            return ValueListenableBuilder<String?>(
              valueListenable: GlobalFabController.currentRoute,
              builder: (context, currentRoute, _) {
                // Don't show on the tracking screen itself
                if (currentRoute == '/active-incident') return const SizedBox.shrink();

                return Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20, // Bottom of the screen
                  child: Material(
                    color: const Color(0xFFFF5252), // Red Accent style
                    elevation: 10,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'تنبيه استجابة!' : 'Active Response!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'NotoSansArabic',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAr ? 'أنت في طريقك لمساعدة حالة طبية.' : 'You are en route to help a case.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'NotoSansArabic',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              GlobalFabController.navigatorKey.currentState?.push(
                                MaterialPageRoute(
                                  builder: (context) => ActiveIncidentTrackingScreen(
                                    incidentId: activeId,
                                    initialLat: SessionService().activeIncidentLat ?? 0.0,
                                    initialLng: SessionService().activeIncidentLng ?? 0.0,
                                  ),
                                  settings: const RouteSettings(name: '/active-incident'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFFF5252),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              isAr ? 'عرض' : 'Show',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class HoverExpandableFab extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String heroTag;
  final VoidCallback onTap;

  const HoverExpandableFab({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.heroTag,
    required this.onTap,
  });

  @override
  State<HoverExpandableFab> createState() => _HoverExpandableFabState();
}

class _HoverExpandableFabState extends State<HoverExpandableFab> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isAr = AppConfigProvider.of(context).isArabic;

    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExpanded && isAr) ...[
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Icon(widget.icon, color: widget.iconColor),
              if (_isExpanded && !isAr) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GlobalFabRouteObserver extends NavigatorObserver {
  final List<String> excludedRoutes = [
    '/',
    '/landing',
    '/welcome',
    '/login',
    '/signup',
  ];

  void _updateVisibility(Route<dynamic>? route) {
    if (route != null && route is! PageRoute) return;

    final name = route?.settings.name;
    GlobalFabController.currentRoute.value = name;
    if (name == null) return;

    final isExcluded = excludedRoutes.contains(name);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isExcluded) {
        GlobalFabController.hide();
      } else {
        GlobalFabController.show();
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateVisibility(route);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.settings.name == '/chat') {
        GlobalFabController.hideChatButton();
      } else {
        GlobalFabController.showChatButton();
      }
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      _updateVisibility(previousRoute);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GlobalFabController.showChatButton();
      });
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PageRoute) {
      _updateVisibility(previousRoute);
    }
  }
}
