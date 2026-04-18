import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';

// ─────────────────────────────────────────────
//  UI ENUMS (local, derived from SensorModel strings)
// ─────────────────────────────────────────────
enum SensorType { gas, heat }

enum SensorStatus { normal, warning, danger }

SensorType parseSensorType(String t) {
  switch (t) {
    case 'heat':
      return SensorType.heat;
    default:
      return SensorType.gas;
  }
}

SensorStatus parseSensorStatus(String s) {
  switch (s) {
    case 'warning':
      return SensorStatus.warning;
    case 'danger':
      return SensorStatus.danger;
    default:
      return SensorStatus.normal;
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
String sensorTypeName(SensorType t, AppStrings loc) {
  switch (t) {
    case SensorType.gas:
      return loc.gasSensor;
    case SensorType.heat:
      return loc.heatSensor;
  }
}

IconData sensorIcon(SensorType t) {
  switch (t) {
    case SensorType.gas:
      return Icons.air;
    case SensorType.heat:
      return Icons.local_fire_department;
  }
}

String sensorDangerTitle(SensorType t, AppStrings loc) {
  switch (t) {
    case SensorType.gas:
      return loc.sensorDangerTitleGas;
    case SensorType.heat:
      return loc.sensorDangerTitleHeat;
  }
}

List<String> sensorDangerSteps(
  SensorType t,
  String value,
  String unit,
  AppStrings loc,
) {
  switch (t) {
    case SensorType.gas:
      return [
        '${loc.currentReading}: $value $unit',
        loc.gasDangerStep1,
        loc.gasDangerStep2,
        loc.gasDangerStep3,
      ];
    case SensorType.heat:
      return [
        '${loc.heatLabel}: $value$unit',
        loc.heatDangerStep1,
        loc.heatDangerStep2,
        loc.heatDangerStep3,
      ];
  }
}

// ─────────────────────────────────────────────
//  MAIN SENSORS PAGE
// ─────────────────────────────────────────────
class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage>
    with TickerProviderStateMixin {
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
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.96, end: 1.04).animate(_pulseCtrl);
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _shakeAnim = Tween(
      begin: -6.0,
      end: 6.0,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_shakeCtrl);
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
      setState(() {
        _loading = true;
        _error = null;
      });
      final allSensors = await ApiService.fetchSensors();
      final sensors = allSensors.where((s) => s.type != 'smartwatch').toList();
      if (mounted)
        setState(() {
          _sensors = sensors;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  bool get _anyDanger =>
      _sensors.any((s) => parseSensorStatus(s.status) == SensorStatus.danger);
  bool get _allDanger =>
      _sensors.isNotEmpty &&
      _sensors.every((s) => parseSensorStatus(s.status) == SensorStatus.danger);

  /// Updates a sensor locally (optimistic UI) then would sync to server
  void _updateSensorLocally(int id, String newStatus, String newValue) {
    setState(() {
      _sensors = _sensors.map((s) {
        if (s.id != id) return s;
        return s.copyWith(status: newStatus, value: newValue);
      }).toList();
    });
  }

  void _triggerSensor(SensorModel sensor, {bool isWarning = false}) {
    HapticFeedback.heavyImpact();
    String newValue = sensor.value;
    if (sensor.type == 'gas') newValue = isWarning ? '350' : '560';
    if (sensor.type == 'heat') newValue = isWarning ? '55' : '90';

    _updateSensorLocally(sensor.id, isWarning ? 'warning' : 'danger', newValue);

    if (!isWarning) {
      final updated = _sensors.firstWhere((s) => s.id == sensor.id);
      _openEmergencyPage(updated);
    }

    if (_allDanger && !_drillMode) {
      setState(() => _drillMode = true);
      _shakeCtrl.repeat(reverse: true);
    }
  }

  void _triggerAllDanger() {
    HapticFeedback.heavyImpact();
    setState(() {
      _sensors = _sensors.map((s) {
        String newValue = s.type == 'gas' ? '560' : '90';
        return s.copyWith(status: 'danger', value: newValue);
      }).toList();
      _drillMode = true;
    });
    _shakeCtrl.repeat(reverse: true);
    if (_sensors.isNotEmpty) _openEmergencyPage(_sensors[0], isDrill: true);
  }

  void _resetAll() {
    _shakeCtrl.stop();
    _shakeCtrl.reset();
    setState(() => _drillMode = false);
    _loadSensors(); // re-fetch from server (or mock)
  }

  void _openEmergencyPage(SensorModel sensor, {bool isDrill = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SensorEmergencyPage(
          sensor: sensor,
          isDrill: isDrill,
          allSensors: _sensors,
          onReset: () {
            Navigator.pop(context);
            _resetAll();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = _anyDanger;

    return Directionality(
      textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDanger
            ? const Color(0xFF1A0000)
            : Theme.of(context).scaffoldBackgroundColor,
        body: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (ctx, child) => Transform.translate(
            offset: _drillMode ? Offset(_shakeAnim.value, 0) : Offset.zero,
            child: child,
          ),
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(isDanger),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _ErrorBanner(onRetry: _loadSensors)
                    else ...[
                      if (_drillMode) ...[
                        _DrillBanner(
                          onOpen: () => _sensors.isNotEmpty
                              ? _openEmergencyPage(_sensors[0], isDrill: true)
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      ..._sensors.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SensorCard(
                            sensor: s,
                            pulseAnim: _pulseAnim,
                            onTap: () {
                              if (parseSensorStatus(s.status) ==
                                  SensorStatus.danger) {
                                _openEmergencyPage(s);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SensorNormalPage(sensor: s),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TestPanel(
                        sensors: _sensors,
                        onTrigger: _triggerSensor,
                        onTriggerAll: _triggerAllDanger,
                        onReset: _resetAll,
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool isDanger) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: isDanger
          ? const Color(0xFFDC2626)
          : const Color(0xFF16A34A),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDanger
                  ? [const Color(0xFF7F1D1D), const Color(0xFFDC2626)]
                  : [const Color(0xFF14532D), const Color(0xFF16A34A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isDanger
                              ? context.loc.emergencyAlert
                              : context.loc.sensorMonitoringSystem,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadSensors,
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'موقعك: يتم التحديث من GPS...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ERROR BANNER
// ─────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            context.loc.cannotReachServer,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.loc.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NORMAL SENSOR DETAIL PAGE
// ─────────────────────────────────────────────
class SensorNormalPage extends StatelessWidget {
  final SensorModel sensor;
  const SensorNormalPage({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final type = parseSensorType(sensor.type);
    return Directionality(
      textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          title: Text(
            sensorTypeName(type, context.loc),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF166534), Color(0xFF16A34A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(sensorIcon(type), color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '${sensor.value}${sensor.unit}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.loc.safeStatus,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white60,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${sensor.lat.toStringAsFixed(6)}, ${sensor.lng.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black26
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('👍', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 8),
                    Text(
                      context.loc.noProblemsTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.loc.allNormalDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
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

// ─────────────────────────────────────────────
//  FULL-SCREEN EMERGENCY PAGE
// ─────────────────────────────────────────────
class SensorEmergencyPage extends StatefulWidget {
  final SensorModel sensor;
  final bool isDrill;
  final List<SensorModel> allSensors;
  final VoidCallback onReset;

  const SensorEmergencyPage({
    super.key,
    required this.sensor,
    required this.isDrill,
    required this.allSensors,
    required this.onReset,
  });

  @override
  State<SensorEmergencyPage> createState() => _SensorEmergencyPageState();
}

class _SensorEmergencyPageState extends State<SensorEmergencyPage>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsLeft = 480;
  bool _reported = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.97, end: 1.03).animate(_pulseCtrl);
    _flashCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _flashAnim = Tween(begin: 0.6, end: 1.0).animate(_flashCtrl);
    _startTimer();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _autoReport();
      }
    });
  }

  void _autoReport() {
    if (_reported) return;
    setState(() => _reported = true);
    _sendReport(auto: true);
  }

  void _imSafe() {
    _timer?.cancel();
    // Tell backend user is safe
    ApiService.markSensorSafe(widget.sensor.id);
    _showSafeDialog();
  }

  void _needHelp() {
    _timer?.cancel();
    setState(() => _reported = true);
    _sendReport(auto: false);
  }

  Future<void> _sendReport({required bool auto}) async {
    // POST to Django backend
    await ApiService.reportEmergency(
      EmergencyReportModel(
        sensorId: widget.sensor.id,
        type: widget.sensor.type,
        lat: widget.sensor.lat,
        lng: widget.sensor.lng,
        message: auto
            ? (context.loc.isAr
                  ? 'إبلاغ تلقائي — لم يستجب المستخدم'
                  : 'Automatic Report - User did not respond')
            : (context.loc.isAr
                  ? 'طلب مساعدة يدوي من المستخدم'
                  : 'Manual Help Request from User'),
      ),
    );
    _showConfirmation(auto: auto);
  }

  void _showSafeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F172A)
              : Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              Text(
                context.loc.everythingFineSafe,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.loc.cancelAlertSuccess,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onReset();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    context.loc.okBtn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmation({required bool auto}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: const Color(0xFF0F172A),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                auto ? context.loc.reportedAuto : context.loc.reportedManual,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _confRow(
                      Icons.location_on,
                      context.loc.yourLocation,
                      '${widget.sensor.lat.toStringAsFixed(4)}, ${widget.sensor.lng.toStringAsFixed(4)}',
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    _confRow(
                      Icons.local_hospital,
                      context.loc.ambulance,
                      '123',
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    _confRow(
                      Icons.local_fire_department,
                      context.loc.fireDept,
                      '180',
                    ),
                    const Divider(color: Color(0xFF334155), height: 16),
                    _confRow(Icons.security, context.loc.civilDefense, '115'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.loc.authoritiesOnWay,
                style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onReset();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    context.loc.okGotIt,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFEF4444), size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mins = _secondsLeft ~/ 60;
    final secs = _secondsLeft % 60;
    final isUrgent = _secondsLeft < 120;
    final type = parseSensorType(widget.sensor.type);
    final steps = sensorDangerSteps(
      type,
      widget.sensor.value,
      widget.sensor.unit,
      context.loc,
    );
    final isAr = context.loc.isAr;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFCC0000),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F0000), Color(0xFFCC0000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      Row(
                        children: [
                          FadeTransition(
                            opacity: _flashAnim,
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.loc.emergencyAlert,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: isAr
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.loc.timeLabel,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Countdown
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: isUrgent
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          isUrgent
                              ? context.loc.autoReportStatusUrgent
                              : context.loc.timeRemaining,
                          style: TextStyle(
                            color: isUrgent
                                ? const Color(0xFFFFD700)
                                : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Danger info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: isAr
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                sensorDangerTitle(type, context.loc),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...steps.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          s,
                                          textAlign: context.loc.isAr
                                              ? TextAlign.right
                                              : TextAlign.left,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Location
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: context.loc.isAr
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!context.loc.isAr)
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  if (!context.loc.isAr)
                                    const SizedBox(width: 8),
                                  Text(
                                    context.loc.locationDetails,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (context.loc.isAr)
                                    const SizedBox(width: 8),
                                  if (context.loc.isAr)
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _locRow(
                                context.loc.latitudeLabel,
                                widget.sensor.lat.toStringAsFixed(6),
                              ),
                              _locRow(
                                context.loc.longitudeLabel,
                                widget.sensor.lng.toStringAsFixed(6),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.loc.autoReportWarning,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                textAlign: context.loc.isAr
                                    ? TextAlign.right
                                    : TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Contacts
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: context.loc.isAr
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!context.loc.isAr)
                                    const Icon(
                                      Icons.phone_in_talk,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  if (!context.loc.isAr)
                                    const SizedBox(width: 8),
                                  Text(
                                    context.loc.emergencyContactsHeader,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (context.loc.isAr)
                                    const SizedBox(width: 8),
                                  if (context.loc.isAr)
                                    const Icon(
                                      Icons.phone_in_talk,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _contactRow(context.loc.ambulance, '123'),
                              _contactRow(context.loc.fireDept, '180'),
                              _contactRow(context.loc.civilDefense, '115'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            isAr
                                ? '⚡  هيتم إرسال إشعار تلقائي بعد ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} دقيقة  ⚡'
                                : '⚡  Auto-report will be sent in ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} min  ⚡',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _imSafe,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: Text(
                              context.loc.imSafeBtn,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _needHelp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: Text(
                              context.loc.needHelpBtn,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Widget _locRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _contactRow(String label, String number) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  DRILL BANNER
// ─────────────────────────────────────────────
class _DrillBanner extends StatelessWidget {
  final VoidCallback? onOpen;
  const _DrillBanner({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text('🚨', style: TextStyle(fontSize: 26)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.safetyDrillTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    context.loc.safetyDrillDesc,
                    style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              context.loc.isAr ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SENSOR CARD
// ─────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  final SensorModel sensor;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _SensorCard({
    required this.sensor,
    required this.pulseAnim,
    required this.onTap,
  });

  Color get _color {
    switch (parseSensorStatus(sensor.status)) {
      case SensorStatus.normal:
        return const Color(0xFF16A34A);
      case SensorStatus.warning:
        return const Color(0xFFD97706);
      case SensorStatus.danger:
        return const Color(0xFFDC2626);
    }
  }

  String get _statusLabel {
    switch (parseSensorStatus(sensor.status)) {
      case SensorStatus.normal:
        return 'آمن ✅';
      case SensorStatus.warning:
        return 'تحذير ⚠️';
      case SensorStatus.danger:
        return 'خطر 🚨';
    }
  }

  String get _readingLabel {
    switch (parseSensorType(sensor.type)) {
      case SensorType.gas:
        return 'تركيز الغاز في الهواء';
      case SensorType.heat:
        return 'درجة الحرارة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = parseSensorStatus(sensor.status) == SensorStatus.danger;
    final isWarning = parseSensorStatus(sensor.status) == SensorStatus.warning;
    final type = parseSensorType(sensor.type);

    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_color.withOpacity(0.85), _color],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.4),
              blurRadius: isDanger ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(sensorIcon(type), color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensorTypeName(type, context.loc),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _statusLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: Colors.white54, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${sensor.value}${sensor.unit}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _readingLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${sensor.lat.toStringAsFixed(4)}, ${sensor.lng.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            if (isDanger) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text('🚨', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اضغط لعرض تفاصيل الخطر والإجراءات الفورية',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isWarning) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type == SensorType.gas
                            ? 'تركيز الغاز ارتفع! افتح الشبابيك'
                            : 'الحرارة مرتفعة! فعّل التهوية',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return isDanger ? ScaleTransition(scale: pulseAnim, child: card) : card;
  }
}

// ─────────────────────────────────────────────
//  TEST PANEL
// ─────────────────────────────────────────────
class _TestPanel extends StatelessWidget {
  final List<SensorModel> sensors;
  final void Function(SensorModel, {bool isWarning}) onTrigger;
  final VoidCallback onTriggerAll;
  final VoidCallback onReset;

  const _TestPanel({
    required this.sensors,
    required this.onTrigger,
    required this.onTriggerAll,
    required this.onReset,
  });

  SensorModel? _find(String type) {
    try {
      return sensors.firstWhere((s) => s.type == type);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gas = _find('gas');
    final heat = _find('heat');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, color: Color(0xFF6366F1), size: 22),
              const SizedBox(width: 8),
              Text(
                'اختبار الحساسات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (gas != null) ...[
            _btn(
              'تفعيل تسريب غاز 💨',
              const Color(0xFF16A34A),
              gas.status == 'danger',
              () => onTrigger(gas),
            ),
            const SizedBox(height: 10),
          ],
          if (heat != null) ...[
            _btn(
              'تفعيل حريق 🔥',
              const Color(0xFF16A34A),
              heat.status == 'danger',
              () => onTrigger(heat),
            ),
            const SizedBox(height: 10),
          ],
          _btn(
            '⚠️ تفعيل كل الطوارئ',
            const Color(0xFFEA580C),
            false,
            onTriggerAll,
          ),
          const SizedBox(height: 10),
          _btn('إعادة تعيين الكل 🔄', const Color(0xFF475569), false, onReset),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, bool done, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: done ? const Color(0xFF10B981) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
