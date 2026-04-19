import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sensor_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';

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

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadWatches();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWatches() async {
    try {
      setState(() => _loading = true);
      final all = await ApiService.fetchSensors();
      final watches = all.where((s) => s.type == 'smartwatch').toList();
      if (mounted) setState(() { _watches = watches; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openEmergencyPage(SensorModel watch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WatchEmergencyPage(
          watch: watch,
          onReset: () {
            Navigator.pop(context);
            _loadWatches();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

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
                  _ErrorBanner(onRetry: _loadWatches)
                else ...[
                  ..._watches.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _WatchCard(
                      watch: w,
                      pulseAnim: _pulseAnim,
                      onTap: () {
                        if (w.status == 'danger') {
                          _openEmergencyPage(w);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => WatchDetailPage(watch: w)));
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

class _WatchCard extends StatelessWidget {
  final SensorModel watch;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _WatchCard({required this.watch, required this.pulseAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (watch.status) {
      case 'danger':
        statusColor = const Color(0xFFDC2626);
        statusLabel = loc.lifeDanger;
        statusIcon = Icons.emergency_rounded;
        break;
      case 'warning':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = loc.vitalSignsUnstable;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = const Color(0xFF10B981);
        statusLabel = loc.stableHealthStatus;
        statusIcon = Icons.favorite_rounded;
        break;
    }

    return ScaleTransition(
      scale: watch.status == 'danger' ? pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: statusColor.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.watch_rounded, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${loc.watchMonitoring} #${watch.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'NotoSansArabic')),
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
                  _MetricItem(label: loc.heartRate, value: '${watch.value}', unit: 'bpm', color: Colors.pink, icon: Icons.favorite),
                  _MetricItem(label: loc.oxygenLevel, value: '98', unit: '%', color: Colors.blue, icon: Icons.bubble_chart),
                  _MetricItem(label: loc.caloriesBurned, value: '240', unit: 'kcal', color: Colors.orange, icon: Icons.local_fire_department),
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

class WatchDetailPage extends StatelessWidget {
  final SensorModel watch;
  const WatchDetailPage({super.key, required this.watch});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('${loc.watchMonitoring} #${watch.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
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
                boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
              ),
              child: const Column(
                children: [
                  Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 60),
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

class WatchEmergencyPage extends StatelessWidget {
  final SensorModel watch;
  final VoidCallback onReset;
  const WatchEmergencyPage({super.key, required this.watch, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      backgroundColor: const Color(0xFF1A0606),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Center(child: Icon(Icons.emergency_share_rounded, color: Color(0xFFDC2626), size: 100)),
              const SizedBox(height: 40),
              Text(loc.lifeDanger, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
              const SizedBox(height: 20),
              Text(loc.autoReportStatusUrgent, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'NotoSansArabic')),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                   onPressed: onReset,
                   style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                   child: Text(loc.imSafeBtn, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                   onPressed: () {},
                   style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                   child: Text(loc.needHelpBtn, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 50),
        const SizedBox(height: 16),
        Text(loc.connError, style: const TextStyle(fontWeight: FontWeight.bold)),
        TextButton(onPressed: onRetry, child: Text(loc.retry)),
      ],
    );
  }
}
