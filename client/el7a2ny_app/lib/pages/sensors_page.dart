import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';
import 'emergency_confirmation_page.dart';

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
  final bool _drillMode = false;

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
                    if (ApiService.useMock)
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDanger ? Colors.white : Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
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
            border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(color: statusColor.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
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
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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
                boxShadow: [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10))],
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
                  Text(loc.safeStatus, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(loc.noProblemsTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
                  const SizedBox(height: 10),
                  Text(loc.allNormalDesc, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5, fontFamily: 'NotoSansArabic')),
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

  const SensorEmergencyPage({
    super.key,
    required this.sensor,
    required this.isDrill,
    required this.onReset,
  });

  @override
  State<SensorEmergencyPage> createState() => _SensorEmergencyPageState();
}

class _SensorEmergencyPageState extends State<SensorEmergencyPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _secondsLeft = 135; // 2:15
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        // Trigger automated dispatch here in the future
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
      backgroundColor: const Color(0xFFDC2626), // Solid emergency red
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Header & Icon
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
                      child: const Icon(Icons.report_gmailerrorred_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loc.isAr ? 'تنبيه الحساسات' : 'Sensors Alert',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'NotoSansArabic'),
                      ),
                      Text(
                        loc.isAr ? 'اكتشاف تسريب غاز ؟' : 'Gas Leak Detected?',
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
                    color: Color(0xFFFFD700), // Gold/Yellow timer
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              Text(
                loc.isAr
                    ? 'رد حالاً وإلا سيتم إطلاق بلاغ تلقائي'
                    : 'Respond now or an auto-report will be triggered',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic'),
              ),

              const SizedBox(height: 30),

              // Detection Details Card
              _buildSectionCard(
                title: loc.isAr ? 'تفاصيل الاكتشاف:' : 'Detection Details:',
                child: Column(
                  children: [
                    _buildDetailRow(
                      label: loc.isAr ? 'القيمة الحالية :' : 'Current Value:',
                      value: '${widget.sensor.value} ${widget.sensor.unit}',
                      valueColor: const Color(0xFFFFD700),
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    _buildDetailRow(
                      label: loc.isAr ? 'الحد الآمن :' : 'Safety Limit:',
                      value: widget.sensor.type == 'gas' ? '500 ppm' : '45°C',
                      valueColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildBadge(loc.isAr ? 'عالية' : 'High', Colors.orange),
                        const SizedBox(width: 8),
                        _buildBadge(
                            loc.isAr ? 'المطبخ' : 'Kitchen', Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Safety Measures Card
              _buildSectionCard(
                title: loc.isAr ? '⚠ نصائح أمان بسرعة :' : '⚠ Quick Safety:',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSafetyTip(loc.isAr
                        ? 'لا تستخدم زر الكهرباء خالص'
                        : "Don't use electrical switches"),
                    _buildSafetyTip(
                        loc.isAr ? 'افتح الشبابيك فوراً' : 'Open windows immediately'),
                    _buildSafetyTip(loc.isAr
                        ? 'اخرج من المكان لو تقدر'
                        : 'Evacuate the area if possible'),
                    _buildSafetyTip(loc.isAr
                        ? 'مينفعش ولا عود كبريت أو نار'
                        : 'No matches or flames'),
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
                  child: Text(loc.isAr ? 'إنذار كاذب الوضع تمام' : "False Alarm - All Good",
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
                    backgroundColor: const Color(0xFFFACC15), // Yellow
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(loc.isAr ? 'أكد الطوارئ - بلغ دلوقتى !' : "Confirm Emergency - Dispatch!",
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'NotoSansArabic')),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      {required String label, required String value, required Color valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansArabic')),
        Text(value,
            style: TextStyle(
                color: valueColor, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'NotoSansArabic')),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Text('• ',
              style:
                  TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(tip,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansArabic')),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
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
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))),
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
