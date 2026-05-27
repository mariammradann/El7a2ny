import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';
import 'emergency_confirmation_page.dart';

// ─────────────────────────────────────────────
//  SECURITY CAMERA PAGE
// ─────────────────────────────────────────────
class SecurityCameraPage extends StatefulWidget {
  const SecurityCameraPage({super.key});

  @override
  State<SecurityCameraPage> createState() => _SecurityCameraPageState();
}

class _SecurityCameraPageState extends State<SecurityCameraPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  List<SensorModel> _cameras = [];
  bool _loading = true;
  String? _error;
  Timer? _detectionTimer;
  bool _monitoringEnabled = true;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  SensorModel? _pendingCameraAlert;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      js.context.callMethod('requestNotificationPermission');
    }
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lifecycleState = state;
    });

    if (state == AppLifecycleState.resumed && _pendingCameraAlert != null) {
      final camera = _pendingCameraAlert!;
      _pendingCameraAlert = null;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _monitoringEnabled) {
          _simulateStrangerDetection(camera);
        }
      });
    }
  }

  Future<void> _loadCameras() async {
    try {
      setState(() => _loading = true);
      final all = await ApiService.fetchSensors();
      // Keep fetching 'smartwatch' type from backend, but display as security cameras on client
      final cameras = all.where((s) => s.type == 'smartwatch').toList();
      if (mounted) {
        setState(() { _cameras = cameras; _loading = false; });
        if (cameras.isNotEmpty && _monitoringEnabled) {
          _detectionTimer?.cancel();
          _detectionTimer = Timer(const Duration(seconds: 8), () {
            if (mounted && _monitoringEnabled && _cameras.isNotEmpty) {
              _onStrangerDetected(_cameras.first);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onStrangerDetected(SensorModel camera) {
    if (!mounted) return;
    if (_lifecycleState == AppLifecycleState.resumed) {
      _simulateStrangerDetection(camera);
    } else {
      _pendingCameraAlert = camera;
      _triggerBackgroundNotification(camera);
    }
  }

  void _triggerBackgroundNotification(SensorModel camera) {
    if (kIsWeb) {
      final isAr = context.loc.isAr;
      final title = isAr ? 'تم رصد شخص غريب! 🚨' : 'Stranger Detected! 🚨';
      final body = isAr
          ? 'رصدت الكاميرا #${camera.id} (${camera.userName}) حركة لشخص غير معروف.'
          : 'Camera #${camera.id} (${camera.userName}) detected an unrecognized person.';
      js.context.callMethod('showWebNotification', [title, body]);
    }
  }

  void _simulateStrangerDetection(SensorModel camera) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final loc = context.loc;
        final isAr = loc.isAr;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 16,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency_share_rounded, color: Color(0xFFE61717), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr ? 'تم رصد شخص غريب! 🚨' : 'Stranger Detected! 🚨',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFE61717), fontFamily: 'NotoSansArabic'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isAr 
                      ? 'رصدت الكاميرا #${camera.id} (${camera.userName}) حركة لشخص غير معروف بموقع الكاميرا:'
                      : 'Camera #${camera.id} (${camera.userName}) detected an unrecognized person at:',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lat: ${camera.lat.toStringAsFixed(4)}, Lng: ${camera.lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                
                Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1530124560072-a0c9717d3d45?q=80&w=600',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('REC LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                        child: const Text('CAM_03_DETECTION', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                            content: Text(isAr ? 'تم الحفظ كآمن. لم يتم الإبلاغ عن أي شيء.' : 'Marked as safe. No action taken.'),
                            backgroundColor: Colors.green,
                          ));
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
                          await _reportIntrusion(camera);
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

  Future<void> _reportIntrusion(SensorModel camera) async {
    final loc = context.loc;
    final isAr = loc.isAr;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) {
        throw Exception(isAr ? 'يجب تسجيل الدخول للإبلاغ' : 'User must be logged in to report');
      }
      
      await ApiService.sendEmergencyAlert(
        userId: userId,
        type: 'security',
        lat: camera.lat,
        lng: camera.lng,
        description: isAr 
            ? 'تم رصد اقتحام أو سرقة من الكاميرا الأمنية #${camera.id} (${camera.userName}). شخص غريب رصد في إحداثيات الكاميرا.'
            : '[AUTOMATED CAMERA REPORT] Intrusion detected by Security Camera #${camera.id} (${camera.userName}). An unrecognized person was flagged as an active threat.',
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isAr ? 'تم الإبلاغ بنجاح! 🚨' : 'Reported Successfully! 🚨', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
            content: Text(
              isAr 
                  ? 'تم تسجيل بلاغ سرقة وإرساله فوراً للجهات المختصة وتنبيه المتطوعين من حولك.'
                  : 'A theft emergency report has been created. Authorities and nearby citizens have been notified.',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.okBtn),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'فشل الإرسال: $e' : 'Failed to send report: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _openEmergencyPage(SensorModel camera) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraEmergencyPage(
          camera: camera,
          onReset: () {
            Navigator.pop(context);
            _loadCameras();
          },
        ),
      ),
    );
  }

  void _showAddCameraDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCameraBottomSheet(
        onSaved: () {
          _loadCameras();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final isAr = loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add_rounded, color: theme.colorScheme.onSurface, size: 28),
                onPressed: () => _showAddCameraDialog(context),
              ),
              const SizedBox(width: 8),
            ],
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(loc.watchMonitoring, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  _ErrorBanner(onRetry: _loadCameras)
                else ...[
                  // Premium Control Toggle Card for Active Camera Monitoring
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _monitoringEnabled
                            ? [theme.primaryColor.withValues(alpha: 0.15), theme.primaryColor.withValues(alpha: 0.05)]
                            : [Colors.grey.withValues(alpha: 0.15), Colors.grey.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _monitoringEnabled
                            ? theme.primaryColor.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _monitoringEnabled
                              ? theme.primaryColor.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SwitchListTile.adaptive(
                      value: _monitoringEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _monitoringEnabled = value;
                          if (!_monitoringEnabled) {
                            _detectionTimer?.cancel();
                          } else {
                            if (_cameras.isNotEmpty) {
                              _detectionTimer?.cancel();
                              _detectionTimer = Timer(const Duration(seconds: 8), () {
                                if (mounted && _monitoringEnabled && _cameras.isNotEmpty) {
                                  _onStrangerDetected(_cameras.first);
                                }
                              });
                            }
                          }
                        });
                      },
                      title: Text(
                        isAr ? 'مراقبة الكاميرات النشطة' : 'Active Camera Monitoring',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      subtitle: Text(
                        _monitoringEnabled
                            ? (isAr ? 'النظام يراقب ويبحث عن أي حركة مريبة' : 'System is monitoring and scanning for suspicious activity')
                            : (isAr ? 'النظام معطل حالياً' : 'Monitoring is currently offline'),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansArabic',
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      secondary: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _monitoringEnabled
                              ? theme.primaryColor.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _monitoringEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          color: _monitoringEnabled ? theme.primaryColor : Colors.grey,
                          size: 24,
                        ),
                      ),
                      activeColor: theme.primaryColor,
                      activeTrackColor: theme.primaryColor.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade700,
                    ),
                  ),
                  ..._cameras.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _CameraCard(
                      camera: c,
                      pulseAnim: _pulseAnim,
                      monitoringEnabled: _monitoringEnabled,
                      onTap: () {
                        if (!_monitoringEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              isAr 
                                  ? 'يرجى تفعيل المراقبة أولاً لعرض تفاصيل الكاميرا.' 
                                  : 'Please enable monitoring first to view camera details.',
                              style: const TextStyle(fontFamily: 'NotoSansArabic'),
                            ),
                            backgroundColor: Colors.orange,
                          ));
                          return;
                        }
                        if (c.status == 'danger') {
                          _openEmergencyPage(c);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CameraDetailPage(camera: c)));
                        }
                      },
                    ),
                  )),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final SensorModel camera;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  final bool monitoringEnabled;

  const _CameraCard({
    required this.camera,
    required this.pulseAnim,
    required this.onTap,
    required this.monitoringEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (!monitoringEnabled) {
      statusColor = Colors.grey;
      statusLabel = loc.isAr ? 'مغلقة / متوقفة' : 'Turned Off / Offline';
      statusIcon = Icons.videocam_off_rounded;
    } else {
      switch (camera.status) {
        case 'danger':
          statusColor = const Color(0xFFE61717);
          statusLabel = loc.lifeDanger;
          statusIcon = Icons.emergency_rounded;
          break;
        case 'warning':
          statusColor = const Color(0xFFFDC800);
          statusLabel = loc.vitalSignsUnstable;
          statusIcon = Icons.warning_amber_rounded;
          break;
        default:
          statusColor = const Color(0xFF10B981);
          statusLabel = loc.stableHealthStatus;
          statusIcon = Icons.videocam_rounded;
          break;
      }
    }

    return ScaleTransition(
      scale: (monitoringEnabled && camera.status == 'danger') ? pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: statusColor.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${loc.smartWatch} #${camera.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'NotoSansArabic')),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 6),
                            Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'NotoSansArabic')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricItem(label: loc.heartRate, value: monitoringEnabled ? camera.value : '0', unit: 'fps', color: monitoringEnabled ? Colors.blue : Colors.grey, icon: monitoringEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded),
                  _MetricItem(label: loc.oxygenLevel, value: monitoringEnabled ? '98' : '0', unit: '%', color: monitoringEnabled ? Colors.green : Colors.grey, icon: Icons.wifi),
                  _MetricItem(label: loc.caloriesBurned, value: monitoringEnabled ? '240' : '0', unit: 'GB', color: monitoringEnabled ? const Color(0xFFF18F34) : Colors.grey, icon: Icons.storage_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  final IconData icon;
  const _MetricItem({required this.label, required this.value, required this.unit, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
      ],
    );
  }
}

class CameraDetailPage extends StatelessWidget {
  final SensorModel camera;
  const CameraDetailPage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('${loc.smartWatch} #${camera.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withBlue(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 10))],
              ),
              child: const Column(
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.white, size: 60),
                  SizedBox(height: 20),
                  Text('Active Monitoring', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                  SizedBox(height: 4),
                  Text('Everything looks good', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraEmergencyPage extends StatefulWidget {
  final SensorModel camera;
  final VoidCallback onReset;

  const CameraEmergencyPage({
    super.key,
    required this.camera,
    required this.onReset,
  });

  @override
  State<CameraEmergencyPage> createState() => _CameraEmergencyPageState();
}

class _CameraEmergencyPageState extends State<CameraEmergencyPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _secondsLeft = 75; // 1:15
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      backgroundColor: const Color(0xFFE61717), // Emergency red
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loc.isAr ? 'تنبيه أمني' : 'Security Alert',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'NotoSansArabic'),
                      ),
                      Text(
                        loc.isAr ? 'اختراق أمني مكتشف' : 'Security Breach Detected',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansArabic'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Timer
              Text(
                _formatTime(_secondsLeft),
                style: const TextStyle(
                    color: Color(0xFFFDC800),
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              Text(
                loc.isAr
                    ? 'لو سمحت رد وإلا الكاميرا هتبعت إشعارات لجهات الاتصال الطارئة'
                    : 'Please respond or the camera will notify emergency contacts',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic'),
              ),

              const SizedBox(height: 30),

              // Camera Data Grid
              Text(
                loc.isAr ? 'بيانات الكاميرا الحالية :' : 'Current Camera Data:',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 20),
              _buildVitalGrid(context),

              const SizedBox(height: 24),

              // Safety Measures Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.isAr ? '⚠ إرشادات سريعة :' : '⚠ Quick Guidelines:',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'NotoSansArabic')),
                    const SizedBox(height: 12),
                    _buildSafetyTip(loc.isAr ? 'افحص البث المباشر للغرف الأخرى' : 'Check the live feed from other rooms'),
                    _buildSafetyTip(loc.isAr ? 'تأكد من إغلاق جميع الأبواب والنوافذ' : 'Lock all doors and windows'),
                    _buildSafetyTip(loc.isAr ? 'انتقل إلى غرفة آمنة إذا لزم الأمر' : 'Move to a safe room if necessary'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Actions
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: widget.onReset,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(loc.isAr ? 'إنذار خاطئ' : "False Alarm",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'NotoSansArabic')),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyConfirmationPage()));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFDC800),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(loc.isAr ? 'محتاج مساعدة بلغ الطوارئ' : "Need Help - Dispatch SOS",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'NotoSansArabic')),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildVitalCard(context, 'معدل الإطارات', '${widget.camera.value} fps', 'طبيعي', Icons.videocam_rounded, Colors.blue, 'طبيعي')),
            const SizedBox(width: 16),
            Expanded(child: _buildVitalCard(context, 'قوة الإشارة', '92%', 'ضعيف', Icons.wifi, Colors.green, 'ضعيف')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildVitalCard(context, 'جودة الفيديو', '1080p', 'عالي', Icons.speed_rounded, const Color(0xFFF18F34), 'عالي')),
            const SizedBox(width: 16),
            Expanded(child: _buildVitalCard(context, 'مستوى الحركة', '95%', 'حركة مشبوهة', Icons.motion_photos_on_rounded, Colors.purple, 'مشبوهة')),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalCard(BuildContext context, String label, String value, String unit, IconData icon, Color color, String alert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF18F34).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFF18F34)),
                    const SizedBox(width: 2),
                    Text(alert, style: const TextStyle(color: Color(0xFFF18F34), fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(tip, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'NotoSansArabic')),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBanner({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFE61717), size: 50),
        const SizedBox(height: 16),
        Text(loc.connError, style: const TextStyle(fontWeight: FontWeight.bold)),
        TextButton(onPressed: onRetry, child: Text(loc.retry)),
      ],
    );
  }
}

class _AddCameraBottomSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddCameraBottomSheet({required this.onSaved});

  @override
  State<_AddCameraBottomSheet> createState() => _AddCameraBottomSheetState();
}

class _AddCameraBottomSheetState extends State<_AddCameraBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _fpsCtrl = TextEditingController(text: '30');
  final _signalCtrl = TextEditingController(text: '95');
  final _storageCtrl = TextEditingController(text: '120');
  final _latCtrl = TextEditingController(text: '30.0444');
  final _lngCtrl = TextEditingController(text: '31.2357');
  
  String _model = 'Ring Video Doorbell';
  String _status = 'normal';
  bool _fetchingLocation = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fpsCtrl.dispose();
    _signalCtrl.dispose();
    _storageCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled.'),
        ));
        setState(() => _fetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permission denied.'),
          ));
          setState(() => _fetchingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permission denied forever.'),
        ));
        setState(() => _fetchingLocation = false);
        return;
      } 

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _latCtrl.text = position.latitude.toStringAsFixed(6);
        _lngCtrl.text = position.longitude.toStringAsFixed(6);
        _fetchingLocation = false;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final loc = context.loc;
    
    final name = _nameCtrl.text.trim();
    final fps = _fpsCtrl.text.trim();
    final signal = _signalCtrl.text.trim();
    final storage = _storageCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.trim()) ?? 30.0444;
    final lng = double.tryParse(_lngCtrl.text.trim()) ?? 31.2357;
    
    final newCamera = SensorModel(
      id: 0,
      type: 'smartwatch',
      value: fps,
      unit: 'fps',
      status: _status,
      lat: lat,
      lng: lng,
      alertLevel: _status == 'danger' ? 'ALERT' : (_status == 'warning' ? 'WARNING' : 'NORMAL'),
      alertLabel: _status == 'danger' ? '🚨 ALERT' : (_status == 'warning' ? '⚠️ WARNING' : '🟢 NORMAL'),
      isAlert: _status == 'danger',
      humidity: double.tryParse(signal) ?? 95,
      userName: name.isNotEmpty ? name : '$_model Camera',
      updatedAt: DateTime.now(),
    );

    await ApiService.saveLocalSensor(newCamera);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 24),
              Text(
                isAr ? 'إضافة كاميرا أمنية جديدة' : 'Add New Security Camera',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _model,
                items: const [
                  DropdownMenuItem(value: 'Ring Video Doorbell', child: Text('Ring Video Doorbell')),
                  DropdownMenuItem(value: 'Arlo Pro', child: Text('Arlo Pro')),
                  DropdownMenuItem(value: 'Nest Cam', child: Text('Nest Cam')),
                  DropdownMenuItem(value: 'Hikvision', child: Text('Hikvision')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _model = v!),
                decoration: InputDecoration(
                  labelText: isAr ? 'طراز الكاميرا' : 'Camera Model',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم الكاميرا / الموقع' : 'Camera Name / Location',
                  hintText: isAr ? 'مثال: كاميرا الحديقة' : 'e.g. Backyard Camera',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? loc.requiredField : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _status,
                items: [
                  DropdownMenuItem(value: 'normal', child: Text(isAr ? 'مستقرة (آمنة)' : 'Stable (Safe)')),
                  DropdownMenuItem(value: 'warning', child: Text(isAr ? 'إشارة غير مستقرة (تحذير)' : 'Signal Unstable (Warning)')),
                  DropdownMenuItem(value: 'danger', child: Text(isAr ? 'اختراق أمني مكتشف (طوارئ)' : 'Security Breach (Danger)')),
                ],
                onChanged: (v) => setState(() => _status = v!),
                decoration: InputDecoration(
                  labelText: isAr ? 'حالة الكاميرا الحالية' : 'Current Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fpsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAr ? 'معدل الإطارات (FPS)' : 'Frame Rate (FPS)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? loc.requiredField : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _signalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAr ? 'قوة الإشارة (%)' : 'Signal Strength (%)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? loc.requiredField : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _storageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'المساحة المستخدمة (GB)' : 'Storage Used (GB)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? loc.requiredField : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isAr ? 'خط العرض (Lat)' : 'Latitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? loc.requiredField : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isAr ? 'خط الطول (Lng)' : 'Longitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? loc.requiredField : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: _fetchingLocation ? null : _getCurrentLocation,
                icon: _fetchingLocation 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
                label: Text(
                  isAr ? 'جلب موقع الكاميرا الحالي' : 'Get Current Location',
                  style: const TextStyle(fontFamily: 'NotoSansArabic'),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isAr ? 'إضافة الكاميرا' : 'Add Camera',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
