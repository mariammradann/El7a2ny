import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';

// ─────────────────────────────────────────────
//  UI ENUMS & HELPERS
// ─────────────────────────────────────────────
enum SensorType { gas, heat }
enum SensorStatus { normal, warning, danger }

SensorType parseSensorType(String t) {
  if (t == 'heat') return SensorType.heat;
  return SensorType.gas;
}

SensorStatus parseSensorStatus(String s) {
  if (s == 'warning') return SensorStatus.warning;
  if (s == 'danger') return SensorStatus.danger;
  return SensorStatus.normal;
}

String sensorTypeName(SensorType t, AppStrings loc) {
  return t == SensorType.gas ? loc.gasSensor : loc.heatSensor;
}

IconData sensorIcon(SensorType t) {
  return t == SensorType.gas ? Icons.air_rounded : Icons.local_fire_department_rounded;
}

class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> with TickerProviderStateMixin {
  List<SensorModel> _sensors = [];
  bool _loading = true;
  String? _error;
  bool _drillMode = false;

  late AnimationController _pulseCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    
    _shakeCtrl = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _shakeAnim = Tween(begin: -5.0, end: 5.0).animate(_shakeCtrl);
    
    _loadSensors();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSensors() async {
    try {
      setState(() => _loading = true);
      final all = await ApiService.fetchSensors();
      final sensors = all.where((s) => s.type != 'smartwatch').toList();
      if (mounted) setState(() { _sensors = sensors; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  bool get _anyDanger => _sensors.any((s) => parseSensorStatus(s.status) == SensorStatus.danger);

  void _triggerSensor(SensorModel sensor, {bool isWarning = false}) {
    HapticFeedback.heavyImpact();
    String newValue = sensor.type == 'gas' ? (isWarning ? '350' : '560') : (isWarning ? '55' : '90');
    setState(() {
      _sensors = _sensors.map((s) => s.id == sensor.id ? s.copyWith(status: isWarning ? 'warning' : 'danger', value: newValue) : s).toList();
    });
    if (!isWarning) _openEmergencyPage(_sensors.firstWhere((s) => s.id == sensor.id));
  }

  void _openEmergencyPage(SensorModel sensor, {bool isDrill = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SensorEmergencyPage(
          sensor: sensor,
          isDrill: isDrill,
          onReset: () {
            Navigator.pop(context);
            _loadSensors();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDanger = _anyDanger;

    return Scaffold(
      backgroundColor: isDanger ? const Color(0xFF1A0606) : theme.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (ctx, child) => Transform.translate(
          offset: _drillMode ? Offset(_shakeAnim.value, 0) : Offset.zero,
          child: child,
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _SensorSliverAppBar(isDanger: isDanger),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: CircularProgressIndicator()))
                  else if (_error != null)
                    _ErrorBanner(onRetry: _loadSensors)
                  else ...[
                    ..._sensors.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _SensorCard(
                        sensor: s,
                        pulseAnim: _pulseAnim,
                        onTap: () {
                          if (parseSensorStatus(s.status) == SensorStatus.danger) {
                            _openEmergencyPage(s);
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SensorNormalPage(sensor: s)));
                          }
                        },
                      ),
                    )),
                    const SizedBox(height: 12),
                    _TestPanel(sensors: _sensors, onTrigger: _triggerSensor, onReset: _loadSensors),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorSliverAppBar extends StatelessWidget {
  final bool isDanger;
  const _SensorSliverAppBar({required this.isDanger});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: isDanger ? const Color(0xFFDC2626) : Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          loc.sensorsTab,
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontWeight: FontWeight.w900,
            color: isDanger ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        background: isDanger ? Container(color: const Color(0xFFDC2626)) : null,
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final SensorModel sensor;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _SensorCard({required this.sensor, required this.pulseAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final status = parseSensorStatus(sensor.status);
    final type = parseSensorType(sensor.type);
    
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case SensorStatus.danger:
        statusColor = const Color(0xFFDC2626);
        statusLabel = loc.emergencyAlert;
        statusIcon = Icons.report_problem_rounded;
        break;
      case SensorStatus.warning:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = loc.isAr ? 'تحذير' : 'Warning';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case SensorStatus.normal:
        statusColor = const Color(0xFF10B981);
        statusLabel = loc.safeStatus;
        statusIcon = Icons.check_circle_rounded;
        break;
    }

    return ScaleTransition(
      scale: status == SensorStatus.danger ? pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(color: statusColor.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                child: Icon(sensorIcon(type), color: statusColor, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensorTypeName(type, loc),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, fontFamily: 'NotoSansArabic'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sensor.value} ${sensor.unit}',
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'NotoSansArabic'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SensorNormalPage extends StatelessWidget {
  final SensorModel sensor;
  const SensorNormalPage({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final type = parseSensorType(sensor.type);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(sensorTypeName(type, loc), style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withBlue(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Icon(sensorIcon(type), color: Colors.white, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    '${sensor.value} ${sensor.unit}',
                    style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(loc.safeStatus, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(loc.noProblemsTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
                  const SizedBox(height: 10),
                  Text(loc.allNormalDesc, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5, fontFamily: 'NotoSansArabic')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorEmergencyPage extends StatefulWidget {
  final SensorModel sensor;
  final bool isDrill;
  final VoidCallback onReset;

  const SensorEmergencyPage({super.key, required this.sensor, required this.isDrill, required this.onReset});

  @override
  State<SensorEmergencyPage> createState() => _SensorEmergencyPageState();
}

class _SensorEmergencyPageState extends State<SensorEmergencyPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.15).animate(_pulseCtrl);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
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

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final type = parseSensorType(widget.sensor.type);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0606),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                  child: Icon(sensorIcon(type), color: Colors.white, size: 80),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                widget.sensor.type == 'gas' ? loc.sensorDangerTitleGas : loc.sensorDangerTitleHeat,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 16),
              Text(
                loc.autoReportStatusUrgent,
                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
              ),
              const Spacer(),
              _EmergencyActions(onReset: widget.onReset),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyActions extends StatelessWidget {
  final VoidCallback onReset;
  const _EmergencyActions({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            onPressed: onReset,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: Text(loc.imSafeBtn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: Text(loc.needHelpBtn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBanner({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(loc.connError, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: onRetry, child: Text(loc.retry)),
        ],
      ),
    );
  }
}

class _TestPanel extends StatelessWidget {
  final List<SensorModel> sensors;
  final Function(SensorModel, {bool isWarning}) onTrigger;
  final VoidCallback onReset;

  const _TestPanel({required this.sensors, required this.onTrigger, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('DEBUG PANEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: Colors.grey)),
          const SizedBox(height: 16),
          ...sensors.map((s) => Row(
            children: [
              Expanded(child: Text(s.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
              TextButton(onPressed: () => onTrigger(s, isWarning: true), child: const Text('WARN')),
              TextButton(onPressed: () => onTrigger(s), child: const Text('DANGER', style: TextStyle(color: Colors.red))),
            ],
          )),
          const Divider(),
          TextButton(onPressed: onReset, child: const Text('RESET SYSTEM')),
        ],
      ),
    );
  }
}
