import 'package:flutter/material.dart';
import '../pages/emergency_chat_screen.dart';
import '../pages/emergency_report_screen.dart';
import '../core/localization/locale_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../core/auth/auth_token_store.dart';
import 'hover_expandable_fab.dart';

/// A global observer to track visibility of the FABs
class GlobalFabController {
  static final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isChatButtonVisible = ValueNotifier<bool>(true);
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

            final isAr = AppConfigProvider.of(context).isArabic;

            return Positioned(
              left: isAr ? 16 : null,
              right: isAr ? null : 16,
              bottom: 90, // Adjusted to be above the bottom nav bar area
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isAr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    // SOS Button
                    HoverExpandableFab(
                      label: AppConfigProvider.of(context).isArabic ? 'بلاغ طوارئ' : 'Emergency Report',
                      icon: Icons.emergency_share_rounded,
                      backgroundColor: theme.colorScheme.error,
                      iconColor: Colors.white,
                      heroTag: 'global_sos_fab',
                      onTap: () async {
                        final navContext = GlobalFabController.navigatorKey.currentContext;
                        if (navContext != null) {
                          ScaffoldMessenger.of(navContext).showSnackBar(
                            SnackBar(
                              content: Text(AppConfigProvider.of(navContext).isArabic ? 'بدء إجراءات الاستغاثة الفورية...' : 'Initiating instant SOS...'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        // 2. Send location
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

                        // 3. Fetch contacts
                        UserModel? user;
                        try {
                          user = await ApiService.fetchUserProfile();
                        } catch (_) {}

                        // 4. Official calls
                        final officials = ['122', '123', '180'];
                        for (var num in officials) {
                          bool? res = await FlutterPhoneDirectCaller.callNumber(num);
                          if (res == true) await Future.delayed(const Duration(seconds: 10));
                        }

                        // 5. Emergency contacts
                        if (user != null && user.emergencyContacts.isNotEmpty) {
                          for (var contact in user.emergencyContacts) {
                            bool? res = await FlutterPhoneDirectCaller.callNumber(contact.phone);
                            if (res == true) await Future.delayed(const Duration(seconds: 10));
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Chatbot Button
                    ValueListenableBuilder<bool>(
                      valueListenable: GlobalFabController.isChatButtonVisible,
                      builder: (context, chatVisible, _) {
                        if (!chatVisible) return const SizedBox.shrink();
                        return HoverExpandableFab(
                          label: AppConfigProvider.of(context).isArabic ? 'مساعد ذكي' : 'Smart Assistant',
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
            );
          },
        ),
      ],
    );
  }
}

/// Simple observer to toggle FAB visibility based on routes
class GlobalFabRouteObserver extends NavigatorObserver {
  final List<String> excludedRoutes = ['/', '/landing', '/welcome', '/login', '/signup', '/emergency-report'];

  void _updateVisibility(Route<dynamic>? route) {
    // Ignore dropdowns, dialogs, and bottom sheets
    if (route != null && route is! PageRoute) return;

    final name = route?.settings.name;
    if (name == null) return; // Do not guess if name is missing

    final isExcluded = excludedRoutes.contains(name);
    
    debugPrint("GlobalFabRouteObserver: route name=${name}, isExcluded=$isExcluded, routeType=${route.runtimeType}");
    
    if (isExcluded) {
      GlobalFabController.hide();
    } else {
      GlobalFabController.show();
    }

    // Hide chatbot button specifically on its own page
    // We can't always rely on name if it's pushed as a MaterialPageRoute without name
    // But we can check if the route's widget is EmergencyChatScreen if we have access
    // For now, let's assume we might need a more robust way or use a custom name
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateVisibility(route);
    
    // Check if the route being pushed is the chat screen
    // We can check the route settings name if provided, or the widget type
    if (route.settings.name == '/chat' || route is MaterialPageRoute && route.builder(GlobalFabController.navigatorKey.currentContext!) is EmergencyChatScreen) {
      GlobalFabController.hideChatButton();
    } else {
      GlobalFabController.showChatButton();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      _updateVisibility(previousRoute);
      GlobalFabController.showChatButton();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PageRoute) {
      _updateVisibility(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateVisibility(newRoute);
  }
}

