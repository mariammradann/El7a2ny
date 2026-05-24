import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';
import 'alert_details_page.dart';
import '../services/session_service.dart';
import 'package:geolocator/geolocator.dart';
import 'active_incident_tracking_screen.dart';


class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AlertModel> _alerts = [];
  bool _loading = true;
  String? _error;
  Position? _currentPosition;

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
      Position? pos;
      try {
        pos = await _determinePosition();
      } catch (e) {
        debugPrint("Location error: $e");
      }
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _alerts = alerts;
          _loading = false;
        });
        _checkForNearbyAlerts(alerts, pos);
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

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  void _checkForNearbyAlerts(List<AlertModel> alerts, Position? userPos) {
    if (userPos == null) return;
    for (var alert in alerts) {
      if (alert.isMyAlert) continue;
      final distance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        alert.lat,
        alert.lng,
      );
      if (distance <= 5000) {
        _showNearbyNotification(alert);
        break;
      }
    }
  }

  void _showNearbyNotification(AlertModel alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        backgroundColor: const Color(0xFFE61717),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.isAr ? 'تنبيه قريب!' : 'Nearby Alert!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    context.loc.isAr
                        ? 'هناك ${alert.getLocalizedType(context.loc)} بالقرب منك'
                        : '${alert.getLocalizedType(context.loc)} detected near you',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlertDetailsPage(alert: alert),
                  ),
                );
              },
              child: Text(
                context.loc.isAr ? 'عرض' : 'View',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
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
            Text(context.loc.cannotReachServer),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(context.loc.tryAgain),
            ),
          ],
        ),
      );
    }
    final displayAlerts = _alerts.where((a) {
      if (isMyAlerts) return a.isMyAlert;
      final s = a.status.toLowerCase();
      return s != 'resolved' && s != 'completed' && s != 'solved';
    }).where((a) {
      // Admins should see all incidents (no proximity filter)
      if (isMyAlerts || _currentPosition == null || SessionService().isAdmin) return true;
      final dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.lat,
        a.lng,
      );
      return dist <= 5000;
    }).toList();

    if (displayAlerts.isEmpty) {
      return Center(child: Text(context.loc.noAlerts));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: Theme.of(context).primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: displayAlerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (context, i) => _AlertCard(
          alert: displayAlerts[i],
          isMyAlerts: isMyAlerts,
          onRefresh: _load,
        ),
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  final AlertModel alert;
  final bool isMyAlerts;
  final VoidCallback onRefresh;

  const _AlertCard({
    required this.alert,
    required this.isMyAlerts,
    required this.onRefresh,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _adminActionLoading = false;

  AlertModel get alert => widget.alert;
  bool get isMyAlerts => widget.isMyAlerts;

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFE61717); // Red
      case 'high':
        return const Color(0xFFF18F34); // Orange
      case 'medium':
        return const Color(0xFFFDC800); // Yellow-Orange
      case 'low':
        return const Color(0xFFEAB308); // Yellow
      default:
        return const Color(0xFF64748B); // Slate Gray
    }
  }

  Future<void> _doAdminAction(String action) async {
    setState(() => _adminActionLoading = true);
    try {
      await ApiService.adminUpdateIncident(alert.id, action);
      if (mounted) {
        final msg = action == 'monitor'
            ? context.loc.monitoringStartedMsg
            : context.loc.incidentCancelledMsg;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'NotoSansArabic')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: action == 'monitor' ? Colors.blue : const Color(0xFFF18F34),
        ));
        widget.onRefresh();

        // If admin chose to monitor, open the active incident tracking screen and set session
        if (action == 'monitor') {
          SessionService().setActiveIncident(alert.id, lat: alert.lat, lng: alert.lng, role: null);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActiveIncidentTrackingScreen(
                incidentId: alert.id,
                initialLat: alert.lat,
                initialLng: alert.lng,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFE61717),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _adminActionLoading = false);
    }
  }

  Future<void> _doAdminDelete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('حذف البلاغ', style: TextStyle(fontFamily: 'NotoSansArabic')),
            content: const Text('هل أنت متأكد من حذف هذا البلاغ؟',
                style: TextStyle(fontFamily: 'NotoSansArabic')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: const Color(0xFFE61717))),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    setState(() => _adminActionLoading = true);
    try {
      await ApiService.adminDeleteIncident(alert.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.loc.incidentDeletedMsg,
              style: const TextStyle(fontFamily: 'NotoSansArabic')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE61717),
        ));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFE61717),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _adminActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    Color bannerColor;
    IconData largeIcon;

    if (alert.type.contains('fire') || alert.type.contains('حريق')) {
      bannerColor = const Color(0xFFE61717);
      largeIcon = Icons.fire_extinguisher_rounded;
    } else if (alert.type.contains('medical') || alert.type.contains('طب')) {
      bannerColor = const Color(0xFFE95F32);
      largeIcon = Icons.medical_services_rounded;
    } else if (alert.type.contains('security') || alert.type.contains('أمن')) {
      bannerColor = const Color(0xFFE95F32);
      largeIcon = Icons.shield_rounded;
    } else {
      bannerColor = const Color(0xFF6366F1);
      largeIcon = Icons.emergency_rounded;
    }

    final totalVols = alert.totalVolunteers > 0 ? alert.totalVolunteers : 1;
    final currVols = alert.currentVolunteers;
    final progress = ((currVols / totalVols) * 100).round().clamp(0, 100);
    final isAr = context.loc.isAr;
    final dateStr = alert.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(alert.createdAt!)
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AlertDetailsPage(alert: alert, isMyAlerts: isMyAlerts),
          ),
        );
        if (result == true) widget.onRefresh();
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
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      largeIcon,
                      size: 160,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (alert.status.toLowerCase() == 'resolved' ||
                                alert.status.toLowerCase() == 'completed')
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF18F34),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        alert.getLocalizedStatus(context.loc),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMyAlerts ? const Color(0xFFF18F34) : theme.primaryColor,
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.getLocalizedType(context.loc) +
                              (isMyAlerts ? context.loc.pastAlert : context.loc.activeStatus),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                          ),
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                      Text(
                        alert.timeAgoLocalized(context.loc).isEmpty
                            ? context.loc.justNow
                            : alert.timeAgoLocalized(context.loc),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isAr) Icon(Icons.location_on, size: 16, color: theme.primaryColor),
                      if (!isAr) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (alert.address != null && alert.address!.isNotEmpty)
                              ? alert.address!
                              : "${alert.lat.toStringAsFixed(4)}, ${alert.lng.toStringAsFixed(4)}",
                          style: TextStyle(
                            fontSize: 13,
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                      if (isAr) const SizedBox(width: 4),
                      if (isAr) Icon(Icons.location_on, size: 16, color: theme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isAr) const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                      if (!isAr) const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (isAr) const SizedBox(width: 4),
                      if (isAr) const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(alert.severity).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getSeverityColor(alert.severity).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getSeverityColor(alert.severity),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              alert.getLocalizedSeverity(context.loc),
                              style: TextStyle(
                                color: _getSeverityColor(alert.severity),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  
                  // --- UPDATED IMAGE SECTION FOR WEB ---
                  if (alert.mediaUrls != null && alert.mediaUrls!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: alert.mediaUrls!.length,
                        itemBuilder: (context, idx) {
                          String mediaUrl = alert.mediaUrls![idx];
                          
                          // Fix for relative paths and CORS
                          final String fullUrl = mediaUrl.startsWith('http') 
                            ? mediaUrl 
                            : "${ApiService.baseUrl}${mediaUrl.startsWith('/') ? '' : '/'}$mediaUrl";

                          return Padding(
                            padding: EdgeInsets.only(
                              right: isAr ? 8 : 0,
                              left: isAr ? 0 : 8,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fullUrl,
                                fit: BoxFit.cover,
                                width: 100,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: theme.dividerColor),
                                  ),
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // -------------------------------------

                  const SizedBox(height: 20),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_alt_rounded, size: 16, color: theme.primaryColor),
          ),
          const SizedBox(width: 10),
          Text(
            context.loc.volunteers,
            style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 12),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$currVols',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.primaryColor,
                  ),
                ),
                TextSpan(
                  text: ' / ${alert.totalVolunteers}',
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: alert.totalVolunteers > 0
              ? (currVols / alert.totalVolunteers).clamp(0.0, 1.0)
              : 0.0,
          minHeight: 6,
          backgroundColor: isDark
              ? Colors.white12
              : theme.primaryColor.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation<Color>(
            currVols >= alert.totalVolunteers
                ? const Color(0xFF22C55E)
                : theme.primaryColor,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        currVols >= alert.totalVolunteers
            ? (isAr ? 'اكتمل العدد المطلوب' : 'Full capacity reached')
            : (isAr
                ? 'متبقي ${alert.totalVolunteers - currVols} متطوع'
                : '${alert.totalVolunteers - currVols} more needed'),
        style: TextStyle(
          fontSize: 11,
          color: currVols >= alert.totalVolunteers
              ? const Color(0xFF22C55E)
              : onSurface.withValues(alpha: 0.45),
        ),
        textAlign: isAr ? TextAlign.right : TextAlign.left,
      ),
    ],
  ),
),
                  if (SessionService().isAdmin) ...[
                    const Divider(height: 32),
                    if (_adminActionLoading)
                      const Center(child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _AdminActionButton(
                            label: context.loc.actionMonitor,
                            icon: Icons.track_changes_rounded,
                            color: Colors.blue,
                            onTap: () => _doAdminAction('monitor'),
                          ),
                          const SizedBox(width: 8),
                          _AdminActionButton(
                            label: context.loc.actionCancelAlert,
                            icon: Icons.cancel_outlined,
                            color: const Color(0xFFF18F34),
                            onTap: () => _doAdminAction('cancel'),
                          ),
                          const SizedBox(width: 8),
                          _AdminActionButton(
                            label: context.loc.actionDeleteIncident,
                            icon: Icons.delete_outline_rounded,
                            color: const Color(0xFFE61717),
                            onTap: _doAdminDelete,
                          ),
                        ],
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
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}