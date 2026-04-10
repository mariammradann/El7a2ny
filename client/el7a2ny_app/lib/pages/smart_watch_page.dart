import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────
//  SMART WATCH PAGE
// ─────────────────────────────────────────────
class SmartWatchPage extends StatefulWidget {
  const SmartWatchPage({super.key});

  @override
  State<SmartWatchPage> createState() => _SmartWatchPageState();
}

class _SmartWatchPageState extends State<SmartWatchPage> with TickerProviderStateMixin {
  List<SensorModel> _watches = [];
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
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.96, end: 1.04).animate(_pulseCtrl);
    _shakeCtrl = AnimationController(duration: const Duration(milliseconds: 80), vsync: this);
    _shakeAnim = Tween(begin: -6.0, end: 6.0).chain(CurveTween(curve: Curves.easeInOut)).animate(_shakeCtrl);
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() { _loading = true; _error = null; });
      final allSensors = await ApiService.fetchSensors();
      final watchesOnly = allSensors.where((s) => s.type == 'smartwatch').toList();
      if (mounted) setState(() { _watches = watchesOnly; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  bool get _anyDanger => _watches.any((w) => w.status == 'danger');
  bool get _allDanger => _watches.isNotEmpty && _watches.every((w) => w.status == 'danger');

  void _updateWatchLocally(int id, String newStatus, String newValue) {
    setState(() {
      _watches = _watches.map((w) {
        if (w.id != id) return w;
        return w.copyWith(status: newStatus, value: newValue);
      }).toList();
    });
  }

  void _triggerWatch(SensorModel watch, {bool isWarning = false}) {
    HapticFeedback.heavyImpact();
    String newValue = isWarning ? '45'  : '28';

    _updateWatchLocally(watch.id, isWarning ? 'warning' : 'danger', newValue);

    if (!isWarning) {
      final updated = _watches.firstWhere((w) => w.id == watch.id);
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
      _watches = _watches.map((w) => w.copyWith(status: 'danger', value: '28')).toList();
      _drillMode = true;
    });
    _shakeCtrl.repeat(reverse: true);
    if (_watches.isNotEmpty) _openEmergencyPage(_watches[0], isDrill: true);
  }

  void _resetAll() {
    _shakeCtrl.stop();
    _shakeCtrl.reset();
    setState(() => _drillMode = false);
    _loadData();
  }

  void _openEmergencyPage(SensorModel watch, {bool isDrill = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartWatchEmergencyPage(
          watch: watch,
          isDrill: isDrill,
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDanger ? const Color(0xFF1A0000) : const Color(0xFFF0FDF4),
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
                      _ErrorBanner(onRetry: _loadData)
                    else if (_watches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text('لا توجد ساعات متصلة', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                      )
                    else ...[
                      if (_drillMode) ...[
                        _DrillBanner(onOpen: () => _watches.isNotEmpty ? _openEmergencyPage(_watches[0], isDrill: true) : null),
                        const SizedBox(height: 16),
                      ],
                      ..._watches.map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _WatchCard(
                              watch: w,
                              pulseAnim: _pulseAnim,
                              onTap: () {
                                if (w.status == 'danger') {
                                  _openEmergencyPage(w);
                                } else {
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => SmartWatchNormalPage(watch: w)));
                                }
                              },
                            ),
                          )),
                      const SizedBox(height: 8),
                      _TestPanel(
                        watches: _watches,
                        onTrigger: _triggerWatch,
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
      backgroundColor: isDanger ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
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
                  Row(children: [
                    Expanded(child: Text(
                      isDanger ? '⚠️ خطر صحي!' : 'الساعات الذكية',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    )),
                    GestureDetector(
                      onTap: _loadData,
                      child: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.location_on, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text('موقعك: يتم تحديث احداثيات الساعة...',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
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
//  COMPONENTS
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF94A3B8)),
        const SizedBox(height: 10),
        const Text('مش قادر يوصل للسيرفر', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('حاول تاني'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}

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
          gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(children: [
          Text('🚨', style: TextStyle(fontSize: 26)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             Text('⚠️ خطر صحي حرج',
                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
             Text('يوجد خطر على صحة المستخدم - اضغط للتفاصيل',
                 style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 12)),
          ])),
          Icon(Icons.chevron_left, color: Colors.white54),
        ]),
      ),
    );
  }
}

class _WatchCard extends StatelessWidget {
  final SensorModel watch;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _WatchCard({required this.watch, required this.pulseAnim, required this.onTap});

  Color get _color {
    switch (watch.status) {
      case 'warning': return const Color(0xFFD97706);
      case 'danger': return const Color(0xFFDC2626);
      default: return const Color(0xFF16A34A);
    }
  }

  String get _statusLabel {
    switch (watch.status) {
      case 'warning': return 'علامات حيوية غير مستقرة ⚠️';
      case 'danger': return 'خطر على الحياة 🚨';
      default: return 'الحالة الصحية مستقرة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = watch.status == 'danger';
    final isWarning = watch.status == 'warning';

    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_color.withOpacity(0.85), _color],
            begin: Alignment.topRight, end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _color.withOpacity(0.4), blurRadius: isDanger ? 18 : 10, offset: const Offset(0, 6))],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.watch_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('الساعة الذكية',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(_statusLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ])),
            const Icon(Icons.chevron_left, color: Colors.white54, size: 24),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Text('${watch.value}${watch.unit}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('مستوى الأمان / معدل النبض', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.location_on, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text('احداثيات: ${watch.lat.toStringAsFixed(4)}, ${watch.lng.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          if (isDanger) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Text('🚨', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Expanded(child: Text('هبوط حاد في العلامات الحيوية - اضغط للتفاصيل',
                    style: TextStyle(color: Colors.white, fontSize: 12))),
              ]),
            ),
          ],
        ]),
      ),
    );

    return isDanger ? ScaleTransition(scale: pulseAnim, child: card) : card;
  }
}

class _TestPanel extends StatelessWidget {
  final List<SensorModel> watches;
  final void Function(SensorModel, {bool isWarning}) onTrigger;
  final VoidCallback onTriggerAll;
  final VoidCallback onReset;

  const _TestPanel({
    required this.watches, required this.onTrigger,
    required this.onTriggerAll, required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (watches.isEmpty) return const SizedBox.shrink();
    final watch = watches.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.science_rounded, color: Color(0xFF6366F1), size: 22),
          SizedBox(width: 8),
          Text('محاكاة الساعة الذكية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 16),
        _btn('تفعيل خطر صحي', const Color(0xFF16A34A),
            watch.status == 'danger', () => onTrigger(watch)),
        const SizedBox(height: 10),
        _btn('إعادة تعيين الكل 🔄', const Color(0xFF475569), false, onReset),
      ]),
    );
  }

  Widget _btn(String label, Color color, bool done, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFDC2626) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NORMAL PAGE
// ─────────────────────────────────────────────
class SmartWatchNormalPage extends StatelessWidget {
  final SensorModel watch;
  const SmartWatchNormalPage({super.key, required this.watch});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          title: const Text('الساعة الذكية', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF166534), Color(0xFF16A34A)],
                    begin: Alignment.topRight, end: Alignment.bottomLeft),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 48),
                const SizedBox(height: 16),
                Text('${watch.value} bpm',
                    style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('الحالة الجسدية ممتازة ✅', style: TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.my_location_rounded, color: Colors.white60, size: 14),
                  const SizedBox(width: 4),
                  Text('الاحداثيات: ${watch.lat.toStringAsFixed(6)}, ${watch.lng.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
              ),
              child: const Column(children: [
                Text('👍', style: TextStyle(fontSize: 44)),
                SizedBox(height: 8),
                Text('وضع المستخدم مستقر',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                SizedBox(height: 6),
                Text('النبض سليم والمؤشرات الحيوية تعمل بكفاءة وفي المعدل الطبيعي.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMERGENCY PAGE
// ─────────────────────────────────────────────
class SmartWatchEmergencyPage extends StatefulWidget {
  final SensorModel watch;
  final bool isDrill;
  final VoidCallback onReset;

  const SmartWatchEmergencyPage({
    super.key,
    required this.watch,
    required this.isDrill,
    required this.onReset,
  });

  @override
  State<SmartWatchEmergencyPage> createState() => _SmartWatchEmergencyPageState();
}

class _SmartWatchEmergencyPageState extends State<SmartWatchEmergencyPage> with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsLeft = 300; // Faster auto-report for smartwatch (5 mins instead of 8)
  bool _reported = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(_pulseCtrl);
    _startTimer();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) { t.cancel(); _autoReport(); }
    });
  }

  void _autoReport() {
    if (_reported) return;
    setState(() => _reported = true);
    _sendReport(auto: true);
  }

  void _needHelp() {
    _timer?.cancel();
    setState(() => _reported = true);
    _sendReport(auto: false);
  }

  Future<void> _sendReport({required bool auto}) async {
    await ApiService.reportEmergency(EmergencyReportModel(
      sensorId: widget.watch.id,
      type: 'smartwatch',
      lat: widget.watch.lat,
      lng: widget.watch.lng,
      message: auto ? 'الساعة الذكية رصدت هبوط: إبلاغ تلقائي لحالة طوارئ قلبية' : 'طلب إسعاف فوري للمستخدم (الساعة الذكية)',
    ));
    _showConfirmation();
  }

  void _imSafe() {
    _timer?.cancel();
    ApiService.markSensorSafe(widget.watch.id);
    Navigator.pop(context);
    widget.onReset();
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF0F172A),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                  shape: BoxShape.circle),
              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 42)),
            const SizedBox(height: 14),
             const Text('تم إرسال إشعار للإسعاف مع مكانك الحالي! 🚑',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); widget.onReset(); },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('حسناً', style: TextStyle(color: Colors.white, fontSize: 16)),
              )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mins = _secondsLeft ~/ 60;
    final secs = _secondsLeft % 60;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFDC2626),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white70, size: 28),
                  ),
                  const Text('خطر صحي حرج',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(width: 28),
                ]),
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    Text(
                      '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'سوف يتم طلب الإسعاف تلقائيا',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('اجراءات سريعة لحين وصول الدعم:',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('• استلقِ في وضع مريح تماماً على الفور.', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                        SizedBox(height: 8),
                        Text('• ابقِ هادئاً وخذ أنفاساً عميقة.', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                        SizedBox(height: 8),
                        Text('• خذ أدويتك المعتادة في حالة الأزمات إن وجدت.', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [
                            Icon(Icons.location_on, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('موقعك (سيتم إرساله للإسعاف):',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 12),
                          Text('احداثيات: ${widget.watch.lat.toStringAsFixed(6)}, ${widget.watch.lng.toStringAsFixed(6)}',
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ]),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _needHelp,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 18)),
                        child: const Text('أنا في خطر - اطلب الإسعاف فوراً',
                            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                      )),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity,
                      child: TextButton(
                        onPressed: _imSafe,
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18)),
                        child: const Text('أنا بخير (إلغاء الطوارئ)',
                            style: TextStyle(color: Colors.white70, fontSize: 16)),
                      )),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
