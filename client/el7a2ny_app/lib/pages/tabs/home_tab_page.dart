import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../data/models/device_status.dart';
import '../../data/repositories/device_repository.dart';
import '../../widgets/emergency_dashboard_widgets.dart';
import '../dashboard_tab.dart';
import '../alerts_tab.dart';
import '../sponsors_page.dart';
import '../premium_subscription_page.dart';
import '../sensors_page.dart';
import '../smart_watch_page.dart';
import '../../core/localization/app_strings.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

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

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    if (_loading) {
      return ColoredBox(
        color: emergencyPageBg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _status == null) {
      return ColoredBox(
        color: emergencyPageBg,
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
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorText(_error!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      color: emergencyTextDark,
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
    return ColoredBox(
      color: emergencyPageBg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.loc.currentSystem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: emergencyTitleRed,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.loc.responsePlatform,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: emergencySubtitleTeal,
                ),
              ),
              const SizedBox(height: 20),
              EmergencyDashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.loc.deviceStatus,
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: emergencyTextDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EmergencyDeviceStatusRow(
                      icon: Icons.watch_rounded,
                      iconColor: const Color(0xFF1976D2),
                      label: context.loc.smartWatch,
                      connected: status.smartwatchConnected,
                    ),
                    const SizedBox(height: 14),
                    EmergencyDeviceStatusRow(
                      icon: Icons.monitor_heart_outlined,
                      iconColor: const Color(0xFF7B1FA2),
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
                      style: const TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: emergencyTextDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    EmergencySolidButton(
                      label: context.loc.triggerAlert,
                      backgroundColor: const Color(0xFFE53935),
                      onPressed: () =>
                          _toast(context, 'تنبيه الطوارئ — اربطي الـ endpoint'),
                    ),
                    const SizedBox(height: 10),
                    EmergencySolidButton(
                      label: context.loc.sensors,
                      backgroundColor: const Color(0xFF6A1B9A),
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
                      backgroundColor: const Color(0xFF0277BD),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SmartWatchPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    EmergencyGradientButton(
                      label: context.loc.sponsors,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF42A5F5), Color(0xFF7E57C2)],
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
                      backgroundColor: Colors.grey.shade700,
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
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF0F172A),
                                        Color(0xFF1E3A8A),
                                        Color(0xFF3730A3),
                                      ],
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                    ),
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                actions: const [
                                  _PulseBadge(),
                                  SizedBox(width: 8),
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
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: emergencyTextDark,
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
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const PremiumSubscriptionPage(),
                          ),
                        );
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
        color: const Color(0xFF10B981).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
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
              style: const TextStyle(
                color: Color(0xFF6EE7B7),
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
