import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../app/main_shell_screen.dart';
import 'sensors_page.dart';
import 'alert_details_page.dart';
import 'settings_screen.dart';
import '../models/alert_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // We store only IDs, times, and types. Content is localized in build.
  final List<Map<String, dynamic>> _notificationData = [
    {
      'id': 1,
      'type': 'sensor',
      'timeKey': 'justNow',
      'isUnread': true,
    },
    {
      'id': 2,
      'type': 'volunteer',
      'timeValue': '2',
      'timeKey': 'hoursAgo',
      'isUnread': true,
    },
    {
      'id': 3,
      'type': 'incident',
      'timeValue': '5',
      'timeKey': 'hoursAgo',
      'isUnread': false,
    },
    {
      'id': 4,
      'type': 'initiative',
      'timeKey': 'daysAgo',
      'isUnread': false,
    },
    {
      'id': 5,
      'type': 'security',
      'timeKey': 'daysAgo',
      'isUnread': false,
    },
    {
      'id': 6,
      'type': 'system',
      'timeKey': 'daysAgo',
      'isUnread': false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notificationData) {
        n['isUnread'] = false;
      }
    });
  }

  void _handleNotificationTap(Map<String, dynamic> n) {
    setState(() {
      n['isUnread'] = false;
    });

    final type = n['type'];
    
    switch (type) {
      case 'sensor':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SensorsPage()));
        break;
      
      case 'volunteer':
      case 'incident':
        // Navigate to a mock alert details page
        final mockAlert = AlertModel(
          id: n['id'] as int,
          type: type == 'volunteer' ? 'Medical' : 'Fire',
          severity: 'High',
          location: 'Downtown',
          status: 'Active',
          lat: 30.0444,
          lng: 31.2357,
          description: type == 'volunteer' 
            ? 'A volunteer is responding to your emergency request. They are approximately 5 minutes away.' 
            : 'Multiple fire incidents reported in the downtown area. Please stay away from large buildings.',
          currentVolunteers: type == 'volunteer' ? 1 : 12,
          totalVolunteers: type == 'volunteer' ? 1 : 20,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailsPage(alert: mockAlert)));
        break;
      
      case 'initiative':
        // Navigate to Community Tab (index 2 in MainShellScreen)
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const MainShellScreen(initialIndex: 2)),
          (route) => false,
        );
        break;
      
      case 'security':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      
      case 'system':
        // Just go to Home
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const MainShellScreen(initialIndex: 0)),
          (route) => false,
        );
        break;
    }
  }

  String _getLocalizedContent(String type, AppStrings loc) {
    switch (type) {
      case 'sensor': return loc.notifSensorAlertNotif;
      case 'volunteer': return loc.notifVolunteerOnWay;
      case 'incident': return loc.notifIncidentNearby;
      case 'initiative': return loc.notifInitiativeNew;
      case 'security': return loc.notifAccountSecurity;
      case 'system': return loc.notifWelcome;
      default: return '';
    }
  }

  String _getLocalizedTime(Map<String, dynamic> n, AppStrings loc) {
    final key = n['timeKey'];
    final val = n['timeValue'] ?? '';
    
    if (key == 'justNow') return loc.notifJustNow;
    if (key == 'hoursAgo') return '$val ${loc.notifHoursAgo}';
    if (key == 'daysAgo') return '1 ${loc.notifDaysAgo}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    final unreadCount = _notificationData.where((n) => n['isUnread'] == true).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_back_ios_new_rounded, 
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton.icon(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                foregroundColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                isAr ? 'مقروء' : 'Mark all',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'NotoSansArabic'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.notifications,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr 
                    ? 'لديك $unreadCount تنبيهات جديدة' 
                    : 'You have $unreadCount new alerts',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),

          // Notifications List
          Expanded(
            child: _notificationData.isEmpty
                ? _buildEmptyState(theme, loc)
                : ListView.separated(
                    itemCount: _notificationData.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: isAr ? 0 : 80,
                      endIndent: isAr ? 80 : 0,
                      color: theme.dividerColor.withValues(alpha: 0.05),
                    ),
                    itemBuilder: (context, index) {
                      final n = _notificationData[index];
                      return _NotificationItem(
                        content: _getLocalizedContent(n['type'], loc),
                        time: _getLocalizedTime(n, loc),
                        type: n['type'],
                        isUnread: n['isUnread'],
                        onTap: () => _handleNotificationTap(n),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppStrings loc) {
    final isAr = loc.isAr;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: theme.dividerColor.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text(
            isAr ? 'لا توجد إشعارات' : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              fontFamily: 'NotoSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String content;
  final String time;
  final String type;
  final bool isUnread;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.content,
    required this.time,
    required this.type,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = context.loc.isAr;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread 
          ? (isDark ? Colors.blue.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.02))
          : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            _buildIcon(theme),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: isUnread ? 1.0 : 0.8),
                      height: 1.4,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ],
              ),
            ),

            // Unread Indicator
            if (isUnread)
              Container(
                margin: EdgeInsets.only(top: 4, left: isAr ? 0 : 8, right: isAr ? 8 : 0),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'sensor':
        iconData = Icons.sensors_rounded;
        color = Colors.redAccent;
        break;
      case 'volunteer':
        iconData = Icons.volunteer_activism_rounded;
        color = Colors.green;
        break;
      case 'incident':
        iconData = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case 'initiative':
        iconData = Icons.handshake_rounded;
        color = Colors.blue;
        break;
      case 'security':
        iconData = Icons.security_rounded;
        color = Colors.indigo;
        break;
      case 'system':
        iconData = Icons.notifications_active_rounded;
        color = theme.primaryColor;
        break;
      default:
        iconData = Icons.notifications_none_rounded;
        color = theme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}
