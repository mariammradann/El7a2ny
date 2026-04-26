import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';
import '../core/localization/app_strings.dart';
import 'stat_card.dart';
import 'service_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    // Using static data as requested
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _stats = const DashboardStats(
          responseTimeMinutes: 4,
          responseTimeSeconds: 23,
          successRate: 97,
          activeUnits: 142,
          systemHealthy: true,
        );
        _loading = false;
      });
    }
  }

  /// Emergency services — expanded to 6 numbers with image-accurate color palettes
  List<Map<String, dynamic>> _getServices(BuildContext context) {
    final loc = context.loc;
    return [
      {
        'name': loc.police,
        'number': '122',
        'icon': Icons.shield_rounded,
        'gradientColors': const [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Blue
      },
      {
        'name': loc.ambulance,
        'number': '123',
        'icon': Icons.local_hospital_rounded,
        'gradientColors': const [Color(0xFFDC2626), Color(0xFF7F1D1D)], // Maroon/Red
      },
      {
        'name': loc.fireDept,
        'number': '180',
        'icon': Icons.local_fire_department_rounded,
        'gradientColors': const [Color(0xFFEA580C), Color(0xFF9A3412)], // Orange/Brown
      },
      {
        'name': loc.rescue,
        'number': '122',
        'icon': Icons.crisis_alert_rounded,
        'gradientColors': const [Color(0xFF1E40AF), Color(0xFF1E3A8A)], // Navy/Deep Blue
      },
      {
        'name': loc.civilDefense,
        'number': '180',
        'icon': Icons.health_and_safety_rounded,
        'gradientColors': const [Color(0xFF059669), Color(0xFF064E3B)], // Dark Green
      },
      {
        'name': loc.antiDrugs,
        'number': '109',
        'icon': Icons.block_rounded,
        'gradientColors': const [Color(0xFF475569), Color(0xFF1E293B)], // Slate/Charcoal
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(onRetry: _load);
    }

    final stats = _stats!;
    final loc = context.loc;
    final statCards = [
      {'label': loc.responseTime, 'value': stats.responseTimeDisplay, 'unit': loc.minute,
       'gradientColors': const [Color(0xFF10B981), Color(0xFF14B8A6)],
       'icon': Icons.access_time_rounded},
      {'label': loc.successRate,   'value': stats.successRate.toString(), 'unit': '%',
       'gradientColors': const [Color(0xFF3B82F6), Color(0xFF6366F1)],
       'icon': Icons.show_chart_rounded},
      {'label': loc.activeUnits,'value': stats.activeUnits.toString(), 'unit': '',
       'gradientColors': const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
       'icon': Icons.people_alt_rounded},
    ];

    return Directionality(
      textDirection: loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards Row
              Row(
                children: statCards
                    .map((s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: StatCard(
                              label: s['label'] as String,
                              value: s['value'] as String,
                              unit: s['unit'] as String,
                              gradientColors: s['gradientColors'] as List<Color>,
                              icon: s['icon'] as IconData,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              
              // Emergency Services Heading
              Text(loc.emergencyServices,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'NotoSansArabic',
                  )),
              const SizedBox(height: 16),
              
              // Exactly 6 Premium Service Cards
              Column(
                children: _getServices(context)
                    .map((s) => ServiceCard(
                          name: s['name'] as String,
                          number: s['number'] as String,
                          icon: s['icon'] as IconData,
                          gradientColors: s['gradientColors'] as List<Color>,
                          bgColor: Colors.transparent, // Overridden in ServiceCard
                          textColor: Colors.white, // Overridden in ServiceCard
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              
              // Note: Safety Tips and Additional Numbers Grid have been removed per user request
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(context.loc.cannotReachServer, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.loc.tryAgain),
        ),
      ]),
    );
  }
}
