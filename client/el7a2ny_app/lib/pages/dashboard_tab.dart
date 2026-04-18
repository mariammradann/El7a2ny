import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    try {
      setState(() { _loading = true; _error = null; });
      final stats = await ApiService.fetchDashboardStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Emergency numbers — computed dynamically to support translation
  List<Map<String, dynamic>> _getServices(BuildContext context) => [
    {'name': context.loc.police,  'number': '122', 'icon': Icons.shield_rounded,
     'gradientColors': const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
     'bgColor': const Color(0xFFEFF6FF), 'textColor': const Color(0xFF1D4ED8)},
    {'name': context.loc.ambulance, 'number': '123', 'icon': Icons.local_hospital_rounded,
     'gradientColors': const [Color(0xFFDC2626), Color(0xFFB91C1C)],
     'bgColor': const Color(0xFFFFF1F2), 'textColor': const Color(0xFFB91C1C)},
    {'name': context.loc.fireDept, 'number': '180', 'icon': Icons.local_fire_department_rounded,
     'gradientColors': const [Color(0xFFEA580C), Color(0xFFC2410C)],
     'bgColor': const Color(0xFFFFF7ED), 'textColor': const Color(0xFFC2410C)},
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
      {'label': context.loc.responseTime, 'value': stats.responseTimeDisplay, 'unit': context.loc.minute,
       'gradientColors': const [Color(0xFF10B981), Color(0xFF14B8A6)],
       'icon': Icons.access_time_rounded},
      {'label': context.loc.successRate,   'value': stats.successRate.toString(), 'unit': '%',
       'gradientColors': const [Color(0xFF3B82F6), Color(0xFF6366F1)],
       'icon': Icons.show_chart_rounded},
      {'label': context.loc.activeUnits,'value': stats.activeUnits.toString(), 'unit': '',
       'gradientColors': const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
       'icon': Icons.people_alt_rounded},
    ];

    return Directionality(
      textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
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
              Text(context.loc.emergencyServices,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
              const SizedBox(height: 12),
              Column(
                children: _getServices(context)
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
              const SizedBox(height: 32),
  
              // --- Safety Tips ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.loc.safetyTips,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            context.loc.safetyTipsDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: _getTips(context).map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TipCard(
                    title: tip['title'] as String,
                    description: tip['description'] as String,
                    icon: tip['icon'] as IconData,
                    gradientColors: tip['gradientColors'] as List<Color>,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
  
              // --- Important Numbers Grid ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black26
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.additionalImportantNumbers,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _getImportantNumbers(context).length,
                      itemBuilder: (context, i) {
                        final item = _getImportantNumbers(context)[i];
                        final colors = item['gradientColors'] as List<Color>;
                        final number = item['number'] as String;
                        final name = item['name'] as String;
                        return GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse('tel:$number');
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${context.loc.cannotCall}$name ($number)'), backgroundColor: Colors.red),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.loc.errorOccurred}\$e')));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.surface
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
                                        child: Text(
                                          number,
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: colors),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.phone, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
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

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(context.loc.cannotReachServer, style: const TextStyle(color: Color(0xFF64748B), fontSize: 16)),
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

List<Map<String, dynamic>> _getTips(BuildContext context) => [
  {
    'title': context.loc.tip1Title,
    'description': context.loc.tip1Desc,
    'icon': Icons.notifications_active_rounded,
    'gradientColors': const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
  },
  {
    'title': context.loc.tip2Title,
    'description': context.loc.tip2Desc,
    'icon': Icons.location_on_rounded,
    'gradientColors': const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
  },
  {
    'title': context.loc.tip3Title,
    'description': context.loc.tip3Desc,
    'icon': Icons.show_chart_rounded,
    'gradientColors': const [Color(0xFF10B981), Color(0xFF14B8A6)],
  },
];

List<Map<String, dynamic>> _getImportantNumbers(BuildContext context) => [
  {'name': context.loc.police, 'number': '122', 'gradientColors': const [Color(0xFF3B82F6), Color(0xFF6366F1)]},
  {'name': context.loc.ambulance, 'number': '123', 'gradientColors': const [Color(0xFFEF4444), Color(0xFFF97316)]},
  {'name': context.loc.fireDept, 'number': '180', 'gradientColors': const [Color(0xFFF97316), Color(0xFFF59E0B)]},
  {'name': context.loc.rescue, 'number': '112', 'gradientColors': const [Color(0xFF8B5CF6), Color(0xFFEC4899)]},
  {'name': context.loc.antiDrugs, 'number': '122', 'gradientColors': const [Color(0xFF64748B), Color(0xFF475569)]},
  {'name': context.loc.civilDefense, 'number': '180', 'gradientColors': const [Color(0xFF10B981), Color(0xFF14B8A6)]},
];

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: gradientColors[0].withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
