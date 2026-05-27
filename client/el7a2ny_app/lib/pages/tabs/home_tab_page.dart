import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/device_status.dart';
import '../../data/repositories/device_repository.dart';
import '../../widgets/emergency_dashboard_widgets.dart';
import '../../models/sensor_model.dart';
import '../../services/api_service.dart';
import '../dashboard_tab.dart';
import '../alerts_tab.dart';
import '../sponsors_page.dart';
import '../premium_subscription_page.dart';
import '../sensors_page.dart';
import '../security_camera_page.dart';
import '../../core/localization/app_strings.dart';
import '../../services/session_service.dart';
import '../user_rating_screen.dart';
import '../volunteer_rating_screen.dart';
import '../../widgets/artboard_logo.dart';
import '../training_academy_page.dart';

/// الصفحة الرئيسية داخل الـ shell: حالة الأجهزة من الـ API + أزرار الوصول السريع.
class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  final DeviceRepository _deviceRepository = DeviceRepository();

  DeviceStatus? _status;
  Object? _error;
  bool _loading = true;
  Timer? _pollingTimer;
  List<SensorModel> _fireAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _checkForFireAlerts();
    // Poll every 15 seconds to match sensor update interval
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshSilently();
      _checkForFireAlerts();
    });
  }

  /// Check for active fire alerts from sensors
  Future<void> _checkForFireAlerts() async {
    try {
      final alerts = await ApiService.fetchFireAlerts();
      if (!mounted) return;
      setState(() {
        _fireAlerts = alerts;
      });
    } catch (e) {
      print('Error checking fire alerts: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Initial load — shows full loading spinner
  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _deviceRepository.fetchDeviceStatus();
      if (!mounted) return;
      setState(() {
        _status = s;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Silent background refresh — no spinner, just updates status in place
  Future<void> _refreshSilently() async {
    try {
      final s = await _deviceRepository.fetchDeviceStatus();
      if (!mounted) return;
      setState(() {
        _status = s;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      // On silent refresh failure, keep showing last known status
      // but you could optionally mark devices as disconnected here
    }
  }

  String _errorText(Object e) {
    if (e is ApiException) {
      final message = e.message;
      final lower = message.toLowerCase();
      if (lower.contains('connection refused') ||
          lower.contains('failed host lookup') ||
          lower.contains('socketexception')) {
        return context.loc.connError;
      }
      return message;
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = context.loc.isAr;

    // ── Loading ──────────────────────────────────────────────────────────────
    if (_loading) {
      return Container(
        color: getEmergencyPageBg(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (_error != null || _status == null) {
      return Container(
        color: getEmergencyPageBg(context),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorText(_error!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      color: getEmergencyTextDark(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadDevices,
                    child: Text(
                      context.loc.retry,
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final status = _status!;
    final isPlus = SessionService().isPlus;

    // ══════════════════════════════════════════════════════════════════════════
    // PLUS PREMIUM LIGHT UI
    // ══════════════════════════════════════════════════════════════════════════
    if (isPlus) {
      return ListenableBuilder(
        listenable: SessionService(),
        builder: (context, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFBF0), Color(0xFFF5F7FF)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Plus Banner ────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDC800), Color(0xFFF59E0B), Color(0xFFE95F32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFDC800).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'مرحباً بك في إلحقني بلس ⭐' : 'Welcome to El7a2ny Plus ⭐',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr ? 'تمتع بجميع المميزات الحصرية' : 'Enjoy all exclusive features',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'PLUS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Fire Alert (if any) ────────────────────────────────
                    if (_fireAlerts.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE61717), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_fireAlerts.length} ${isAr ? 'تنبيه حريق نشط' : 'active fire alert(s)'}',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Device Status Cards ────────────────────────────────
                    Text(
                      isAr ? 'حالة الأجهزة' : 'Device Status',
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildPlusDeviceCard(
                          icon: Icons.videocam_rounded,
                          label: context.loc.smartWatch,
                          connected: status.smartwatchConnected,
                          color: const Color(0xFF4F46E5),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPlusDeviceCard(
                          icon: Icons.monitor_heart_outlined,
                          label: context.loc.homeSensor,
                          connected: status.homeSensorConnected,
                          color: const Color(0xFF0D9488),
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Quick Actions Buttons ──────────────────────────────
                    Text(
                      isAr ? 'وصول سريع' : 'Quick Access',
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPlusWideButton(
                            icon: Icons.sensors_rounded,
                            label: context.loc.sensors,
                            gradient: const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFFDC2626)]),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SensorsPage())),
                          ),
                          const SizedBox(height: 10),
                          _buildPlusWideButton(
                            icon: Icons.videocam_rounded,
                            label: context.loc.theWatch,
                            gradient: const LinearGradient(colors: [Color(0xFFC2410C), Color(0xFFEA580C)]),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityCameraPage())),
                          ),
                          const SizedBox(height: 10),
                          _buildPlusWideButton(
                            icon: Icons.handshake_rounded,
                            label: context.loc.sponsors,
                            gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFFDC800)]),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SponsorsPage())),
                          ),
                          const SizedBox(height: 10),
                          _buildPlusWideButton(
                            icon: Icons.dashboard_rounded,
                            label: context.loc.emergencyDashboard,
                            gradient: const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)]),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
                              appBar: AppBar(title: Text(context.loc.emergencyDashboard, style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w700))),
                              body: const DashboardTab(),
                            ))),
                          ),
                          const SizedBox(height: 10),
                          _buildPlusWideButton(
                            icon: Icons.warning_amber_rounded,
                            label: context.loc.alerts,
                            gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFF97316)]),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsTab())),
                          ),
                          const SizedBox(height: 10),
                          _buildPlusWideButton(
                            icon: Icons.school_rounded,
                            label: context.loc.trainingAcademy,
                            gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEA580C)]),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrainingAcademyPage())),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),


                    // ── Rate Service ───────────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        final isVolunteer = SessionService().currentRole == UserRole.volunteer;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => isVolunteer ? const VolunteerRatingScreen() : const UserRatingScreen(),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDC800).withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFDC800), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'تقييم الخدمة' : 'Rate Service',
                              style: const TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // STANDARD (NON-PLUS) UI
    // ══════════════════════════════════════════════════════════════════════════
    return Container(
      color: getEmergencyPageBg(context),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔥 FIRE ALERT BANNER
              if (_fireAlerts.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.red.shade900,
                        Colors.orange.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FIRE ALERT DETECTED',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_fireAlerts.length} sensor${_fireAlerts.length > 1 ? 's' : ''} detecting fire',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._fireAlerts.map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Text(
                                '${alert.alertLabel} • ${alert.value}${alert.unit} ${alert.userName != null ? '(${alert.userName})' : ''}',
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on_rounded),
                          label: Text(
                            'View on Sensors',
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const SensorsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              const Center(
                child: ArtboardLogo(size: 350),
              ),
              const SizedBox(height: 10),
              EmergencyDashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.loc.deviceStatus,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: getEmergencyTextDark(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    EmergencyDeviceStatusRow(
                      icon: Icons.videocam_rounded,
                      iconColor: Theme.of(context).colorScheme.primary,
                      label: context.loc.smartWatch,
                      connected: status.smartwatchConnected,
                    ),
                    const SizedBox(height: 14),
                    EmergencyDeviceStatusRow(
                      icon: Icons.monitor_heart_outlined,
                      iconColor: Theme.of(context).colorScheme.secondary,
                      label: context.loc.homeSensor,
                      connected: status.homeSensorConnected,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EmergencyDashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.loc.quickAccess,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: getEmergencyTextDark(context),
                      ),
                    ),
                    const SizedBox(height: 14),

                    EmergencySolidButton(
                      label: context.loc.sensors,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SensorsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    EmergencySolidButton(
                      label: context.loc.theWatch,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SecurityCameraPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    EmergencyGradientButton(
                      label: context.loc.sponsors,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SponsorsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    EmergencySolidButton(
                      label: context.loc.emergencyDashboard,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade700,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  context.loc.emergencyDashboard,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                flexibleSpace: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? [
                                              const Color(0xFF020617),
                                              const Color(0xFF0F172A),
                                              const Color(0xFF1E3A8A),
                                            ]
                                          : [
                                              const Color(0xFF0F172A),
                                              const Color(0xFF1E3A8A),
                                              const Color(0xFF3730A3),
                                            ],
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                    ),
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                actions: [
                                  const _PulseBadge(),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              body: const DashboardTab(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    EmergencySolidButton(
                      label: context.loc.alerts,
                      backgroundColor: theme.brightness == Brightness.light
                          ? Colors.grey.shade400
                          : Colors.grey.shade800,
                      foregroundColor: getEmergencyTextDark(context),
                      height: 44,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const AlertsTab(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    EmergencyGradientButton(
                      label: context.loc.premiumSub,
                      height: 52,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          theme.colorScheme.secondary,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const PremiumSubscriptionPage(),
                            settings: const RouteSettings(name: '/premium'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    EmergencyGradientButton(
                      label: context.loc.trainingAcademy,
                      height: 52,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFDC2626),
                          Color(0xFFEA580C),
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const TrainingAcademyPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    EmergencySolidButton(
                      label: context.loc.isAr ? 'تقييم الخدمة' : 'Rate Service',
                      backgroundColor: const Color(0xFFFDC800),
                      onPressed: () {
                        final isVolunteer = SessionService().currentRole == UserRole.volunteer;
                        if (isVolunteer) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const VolunteerRatingScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UserRatingScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Plus Premium Device Card ───────────────────────────────────────────────
  Widget _buildPlusDeviceCard({
    required IconData icon,
    required String label,
    required bool connected,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFE61717).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              connected ? 'متصل' : 'غير متصل',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: connected ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Plus Wide Button ───────────────────────────────────────────────────────
  Widget _buildPlusWideButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PulseBadge extends StatefulWidget {
  const _PulseBadge();

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
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.2,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.4,
          ),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              context.loc.allSystemsOperational,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF10B981)
                    : const Color(0xFF047857),
                fontSize: 12,
                fontFamily: 'NotoSansArabic',
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
