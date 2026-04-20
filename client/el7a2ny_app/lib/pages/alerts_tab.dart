import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';
import 'alert_details_page.dart';
import '../services/session_service.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AlertModel> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final alerts = await ApiService.fetchAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'NotoSansArabic',
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'NotoSansArabic',
              ),
              tabs: [
                Tab(text: context.loc.activeAlerts),
                Tab(text: context.loc.myAlerts),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildList(isMyAlerts: false), _buildList(isMyAlerts: true)],
      ),
    );
  }

  Widget _buildList({required bool isMyAlerts}) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              context.loc.cannotReachServer,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(context.loc.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final displayAlerts = _alerts
        .where((a) => a.isMyAlert == isMyAlerts)
        .toList();

    if (displayAlerts.isEmpty) {
      return Center(
        child: Text(
          context.loc.noAlerts,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: Theme.of(context).primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: displayAlerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (context, i) =>
            _AlertCard(alert: displayAlerts[i], isMyAlerts: isMyAlerts),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool isMyAlerts;

  const _AlertCard({required this.alert, required this.isMyAlerts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    // Determine colors and faux imagery based on type
    Color bannerColor;
    IconData largeIcon;
    double iconAngle = 0;

    if (alert.type.contains('fire') || alert.type.contains('حريق')) {
      bannerColor = const Color(0xFFEF4444);
      largeIcon = Icons.fire_extinguisher_rounded;
    } else if (alert.type.contains('medical') || alert.type.contains('طب')) {
      bannerColor = const Color(0xFFD97706);
      largeIcon = Icons.medical_services_rounded;
    } else if (alert.type.contains('security') || alert.type.contains('أمن')) {
      bannerColor = const Color(0xFFB45309);
      largeIcon = Icons.shield_rounded;
    } else {
      bannerColor = const Color(0xFF6366F1);
      largeIcon = Icons.emergency_rounded;
    }

    // Use actual progress and volunteers from model
    final totalVols = alert.totalVolunteers > 0 ? alert.totalVolunteers : 1;
    final currVols = alert.currentVolunteers;
    final progress = ((currVols / totalVols) * 100).round().clamp(0, 100);

    final isAr = context.loc.isAr;
    final dateStr = alert.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(alert.createdAt!)
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    final timeColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AlertDetailsPage(alert: alert, isMyAlerts: isMyAlerts),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Image Area
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bannerColor, bannerColor.withValues(alpha: 0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  // Faint Background Icon
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Transform.rotate(
                      angle: iconAngle,
                      child: Icon(
                        largeIcon,
                        size: 160,
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                  // Completed Pill (if my alerts && completed)
                  if (isMyAlerts)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.loc.completed,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Orange/Red Percentage Bubble
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMyAlerts
                            ? const Color(0xFFF97316)
                            : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$progress%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  // Type White Pill
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        alert.getLocalizedType(context.loc),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time & Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          alert.getLocalizedType(context.loc) +
                              (isMyAlerts
                                  ? context.loc.pastAlert
                                  : context.loc.activeStatus),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                          ),
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        alert.timeAgoLocalized(context.loc).isEmpty
                            ? context.loc.justNow
                            : alert.timeAgoLocalized(context.loc),
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location Line
                  Row(
                    mainAxisAlignment: isAr
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isAr)
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                      if (!isAr) const SizedBox(width: 4),
                      Text(
                        alert.getLocalizedLocation(context.loc),
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (isAr) const SizedBox(width: 4),
                      if (isAr)
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date Line
                  Row(
                    mainAxisAlignment: isAr
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isAr)
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      if (!isAr) const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (isAr) const SizedBox(width: 4),
                      if (isAr)
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (alert.description != null)
                    Text(
                      alert.description!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                    ),
                  const SizedBox(height: 20),

                  // Bottom Volunteers Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.loc.volunteers,
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '$currVols ${context.loc.outOfLabel} ${alert.totalVolunteers}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Admin Action Row
                  if (SessionService().isAdmin) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _AdminActionButton(
                            label: context.loc.actionMonitor,
                            icon: Icons.track_changes_rounded,
                            color: Colors.blue,
                            onTap: () {
                              SessionService().logAction('Started monitoring incident: ${alert.type} at ${alert.location}');
                              _showAdminFeedback(context, context.loc.monitoringStartedMsg);
                            },
                          ),
                          const SizedBox(width: 8),
                          _AdminActionButton(
                            label: context.loc.actionCancelAlert,
                            icon: Icons.cancel_outlined,
                            color: Colors.orange,
                            onTap: () {
                              SessionService().logAction('Cancelled incident: ${alert.type} at ${alert.location}');
                              _showAdminFeedback(context, context.loc.incidentCancelledMsg);
                            },
                          ),
                          const SizedBox(width: 8),
                          _AdminActionButton(
                            label: context.loc.actionDeleteIncident,
                            icon: Icons.delete_outline_rounded,
                            color: Colors.red,
                            onTap: () {
                              SessionService().logAction('Permanently deleted record of: ${alert.type} at ${alert.location}');
                              _showAdminFeedback(context, context.loc.incidentDeletedMsg);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminFeedback(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'NotoSansArabic')),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'NotoSansArabic',
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
