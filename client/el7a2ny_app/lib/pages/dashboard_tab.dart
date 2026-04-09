import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';
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
    try {
      setState(() { _loading = true; _error = null; });
      final stats = await ApiService.fetchDashboardStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Emergency numbers — static (official Egyptian numbers, never change)
  static const List<Map<String, dynamic>> _services = [
    {'name': 'الشرطة',  'number': '122', 'icon': Icons.shield_rounded,
     'gradientColors': [Color(0xFF2563EB), Color(0xFF1D4ED8)],
     'bgColor': Color(0xFFEFF6FF), 'textColor': Color(0xFF1D4ED8)},
    {'name': 'الإسعاف', 'number': '123', 'icon': Icons.local_hospital_rounded,
     'gradientColors': [Color(0xFFDC2626), Color(0xFFB91C1C)],
     'bgColor': Color(0xFFFFF1F2), 'textColor': Color(0xFFB91C1C)},
    {'name': 'المطافي', 'number': '180', 'icon': Icons.local_fire_department_rounded,
     'gradientColors': [Color(0xFFEA580C), Color(0xFFC2410C)],
     'bgColor': Color(0xFFFFF7ED), 'textColor': Color(0xFFC2410C)},
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(onRetry: _load);
    }

    final stats = _stats!;
    final statCards = [
      {'label': 'وقت الاستجابة', 'value': stats.responseTimeDisplay, 'unit': 'دقيقة',
       'gradientColors': [const Color(0xFF10B981), const Color(0xFF14B8A6)],
       'icon': Icons.access_time_rounded},
      {'label': 'معدل النجاح',   'value': stats.successRate.toString(), 'unit': '%',
       'gradientColors': [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
       'icon': Icons.show_chart_rounded},
      {'label': 'الوحدات النشطة','value': stats.activeUnits.toString(), 'unit': '',
       'gradientColors': [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
       'icon': Icons.people_alt_rounded},
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: statCards
                  .map((s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
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
            const SizedBox(height: 24),
            const Text('خدمات الطوارئ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Column(
              children: _services
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ServiceCard(
                          name: s['name'] as String,
                          number: s['number'] as String,
                          icon: s['icon'] as IconData,
                          gradientColors: s['gradientColors'] as List<Color>,
                          bgColor: s['bgColor'] as Color,
                          textColor: s['textColor'] as Color,
                        ),
                      ))
                  .toList(),
            ),
          ],
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
        const Text('مش قادر يوصل للسيرفر', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('حاول تاني'),
        ),
      ]),
    );
  }
}
