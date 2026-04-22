import 'package:flutter/material.dart';
import '../pages/emergency_chat_screen.dart';
import '../pages/emergency_report_screen.dart';
import '../core/localization/locale_provider.dart';
import 'hover_expandable_fab.dart';

/// A global observer to track visibility of the FABs
class GlobalFabController {
  static final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void show() => isVisible.value = true;
  static void hide() => isVisible.value = false;
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
                      onTap: () {
                        GlobalFabController.navigatorKey.currentState?.push(
                          MaterialPageRoute<void>(
                            builder: (context) => const EmergencyReportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Chatbot Button
                    HoverExpandableFab(
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
  final List<String> excludedRoutes = ['/', '/landing', '/welcome', '/login', '/signup'];

  void _updateVisibility(Route<dynamic>? route) {
    final name = route?.settings.name;
    // We also check the widget type if name is null (common in pushReplacement)
    final isExcluded = excludedRoutes.contains(name);
    
    // Logic: If it's a known excluded route, hide.
    // In this app, Welcome and Landing are the first ones.
    if (isExcluded) {
      GlobalFabController.hide();
    } else {
      GlobalFabController.show();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateVisibility(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateVisibility(newRoute);
  }
}
