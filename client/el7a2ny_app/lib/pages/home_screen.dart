import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import 'dashboard_tab.dart';
import 'emergency_tab.dart';
import 'safety_tab.dart';
import 'alerts_tab.dart';
import 'sensors_page.dart';
import 'landing_screen.dart';
import '../services/session_service.dart';
import '../services/sensor_service.dart';
import 'active_incident_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  List<Map<String, dynamic>> _getTabs(BuildContext context) => [
    {
      'label': context.loc.dashboard,
      'activeGradient': const [Color(0xFF3B82F6), Color(0xFF6366F1)],
    },
    {
      'label': context.loc.emergencyCall,
      'activeGradient': const [Color(0xFFE61717), Color(0xFFF18F34)],
    },
    {
      'label': context.loc.safetyInfo,
      'activeGradient': const [Color(0xFF10B981), Color(0xFF14B8A6)],
    },
    {
      'label': context.loc.activeAlertsTab,
      'activeGradient': const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    },
    {
      'label': context.loc.sensorsTab,
      'activeGradient': const [Color(0xFF16A34A), Color(0xFF15803D)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _activeTab = widget.initialTabIndex;
    _tabController.addListener(() {
      setState(() => _activeTab = _tabController.index);
    });
    SensorMonitorService().onCameraAlert = (alertData) {
      debugPrint('🏠 HomeScreen received camera alert! mounted=$mounted');
      debugPrint('🏠 Alert data: $alertData');
      if (mounted) {
        _showCameraAlertDialog(alertData);
      } else {
        debugPrint('🏠 NOT MOUNTED — dialog skipped!');
      }
    };
  }

  void _showCameraAlertDialog(Map<String, dynamic> alertData) {
    final isAr = context.loc.isAr;
    final String alertId = alertData['alert_id'];
    final String? imageUrl = alertData['image_url'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 16,
          backgroundColor: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFE61717).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE61717), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'تنبيه: الكاميرا اكتشفت شخصاً غريباً!' : 'Alert: Camera Detected a Stranger!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'NotoSansArabic', color: Color(0xFFE61717)),
                ),
                const SizedBox(height: 12),
                
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[800],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50)),
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 20),
                Text(
                  isAr ? 'هل هذا الشخص آمن ومألوف بالنسبة لك؟' : 'Is this person safe and familiar to you?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ApiService.respondToCameraAlert(alertId, 'reject');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isAr ? 'تم الحفظ كآمن. لم يتم الإبلاغ عن أي شيء.' : 'Marked as safe. No action taken.'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(isAr ? 'آمن / مألوف' : 'Safe / Known', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ApiService.respondToCameraAlert(alertId, 'accept');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isAr ? 'تم إنشاء بلاغ تلقائياً!' : 'Incident created automatically!'),
                              backgroundColor: const Color(0xFFE61717),
                            ));
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE61717),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(isAr ? 'غير آمن - إبلاغ!' : 'Intruder - Report!', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'NotoSansArabic')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs(context);
    return Directionality(
      textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _buildHeader(context),

            // ── Tab Bar ─────────────────────────────────────────────
            _buildTabBar(context, tabs),

            // ── Active Incident Banner ──────────────────────────────
            _buildActiveIncidentBanner(context),

            // ── Tab Content ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  DashboardTab(),
                  EmergencyTab(),
                  SafetyTab(),
                  AlertsTab(),
                  SensorsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionService(),
      builder: (context, _) {
        final isPlus = SessionService().isPlus;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPlus 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF3730A3)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            border: isPlus 
              ? Border(bottom: BorderSide(color: const Color(0xFFFDC800).withOpacity(0.2), width: 1))
              : null,
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 20,
            right: 20,
            left: 20,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Right side: back arrow + logo + title
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LandingScreen()),
                              );
                            }
                          },
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: isPlus 
                              ? [const Color(0xFFFDC800), const Color(0xFFE95F32)]
                              : [const Color(0xFFE61717), const Color(0xFFF18F34)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlus ? Icons.workspace_premium_rounded : Icons.warning_amber_rounded,
                          color: isPlus ? const Color(0xFF0F172A) : Colors.white, 
                          size: 26
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.loc.emergencySystemTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isPlus) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDC800),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PLUS',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            isPlus ? 'إلحقني بلس مفعل' : context.loc.emergencyServices24_7,
                            style: TextStyle(
                              color: isPlus ? const Color(0xFFFDC800).withValues(alpha: 0.8) : const Color(0xFF93C5FD), 
                              fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Left side: status badges
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SensorStatusBadge(),
                      const SizedBox(height: 8),
                      _SystemStatusBadge(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveIncidentBanner(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionService(),
      builder: (context, _) {
        final session = SessionService();
        if (session.activeIncidentId == null) return const SizedBox.shrink();

        final isAr = context.loc.isAr;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE61717), Color(0xFF8A1717)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE61717).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveIncidentTrackingScreen(
                      incidentId: session.activeIncidentId!,
                      initialLat: session.activeIncidentLat,
                      initialLng: session.activeIncidentLng,
                      isCreatorOverride: session.incidentRole == IncidentRole.reporter
                          ? true
                          : session.incidentRole == IncidentRole.volunteer
                              ? false
                              : null,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_searching_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'لديك بلاغ نشط حالياً' : 'Active Incident Tracking',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                          Text(
                            isAr ? 'اضغط للعودة لصفحة التتبع' : 'Tap to return to tracking page',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context, List<Map<String, dynamic>> tabs) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: List<Color>.from(
                  tabs[_activeTab]['activeGradient'] as List),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: tabs
              .map((t) => Tab(text: t['label'] as String))
              .toList(),
        ),
      ),
    );
  }
}

// ── Sensor Status Badge Widget ──────────────────────────────────────────────
class _SensorStatusBadge extends StatelessWidget {
  const _SensorStatusBadge();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SensorMonitorService(),
      builder: (context, _) {
        final sensorService = SensorMonitorService();
        final isConnected = sensorService.isSensorConnected;
        final hasAlerts = sensorService.activeSensorAlerts.isNotEmpty;

        if (hasAlerts) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE61717).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE61717).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE61717),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '⚠ ${context.loc.activeAlertsTab}',
                  style: const TextStyle(
                    color: Color(0xFFE61717),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected 
              ? const Color(0xFF10B981).withValues(alpha: 0.2)
              : const Color(0xFF6B7280).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected 
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : const Color(0xFF6B7280).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFF34D399) : const Color(0xFF9CA3AF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? '🔗 Sensor Connected' : '⚪ No Sensor',
                style: TextStyle(
                  color: isConnected 
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFFD1D5DB),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── System Status Badge Widget (Original Pulse) ──────────────────────────────
class _SystemStatusBadge extends StatefulWidget {
  @override
  State<_SystemStatusBadge> createState() => _SystemStatusBadgeState();
}

class _SystemStatusBadgeState extends State<_SystemStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _opacity = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34D399),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.loc.allSystemsOperationalStatus,
            style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing badge widget (deprecated - replaced by _SensorStatusBadge) ──────
class _PulseBadge extends StatefulWidget {
  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _opacity = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34D399),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.loc.allSystemsOperationalStatus,
            style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
