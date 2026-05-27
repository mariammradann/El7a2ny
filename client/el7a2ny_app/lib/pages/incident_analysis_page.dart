import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/localization/app_strings.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';

class IncidentAnalysisPage extends StatefulWidget {
  const IncidentAnalysisPage({super.key});

  @override
  State<IncidentAnalysisPage> createState() => _IncidentAnalysisPageState();
}

class _IncidentAnalysisPageState extends State<IncidentAnalysisPage> {
  List<AlertModel> _alerts = [];
  bool _loading = true;
  int _totalCount = 0;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAlertsData();
  }

  Future<void> _fetchAlertsData() async {
    try {
      final data = await ApiService.fetchAlerts(all: true);
      if (!mounted) return;
      setState(() {
        _alerts = data;
        _totalCount = data.length;
        _activeCount = data.where((a) => a.status.toLowerCase() == 'active' || a.status.toLowerCase() == 'reported').length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      debugPrint("Error fetching alerts for analysis: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final isAr = loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.analysisTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _StatTile(
                  label: loc.totalIncidents,
                  value: _loading ? '...' : _totalCount.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  label: loc.activeAlerts,
                  value: _loading ? '...' : _activeCount.toString(),
                  color: const Color(0xFFE61717),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _AnalysisCard(
              title: loc.heatMapTitle,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF18F34).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF18F34).withValues(alpha: 0.15),
                    ),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: _alerts.isNotEmpty
                                ? LatLng(_alerts.first.lat, _alerts.first.lng)
                                : const LatLng(30.0444, 31.2357), // Default Cairo
                            initialZoom: 11.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.el7a2ny_app',
                            ),
                            CircleLayer(
                              circles: _alerts
                                  .where((a) => a.lat != 0.0 && a.lng != 0.0)
                                  .map(
                                    (a) => CircleMarker(
                                      point: LatLng(a.lat, a.lng),
                                      color: const Color(0xFFE61717).withValues(alpha: 0.35),
                                      borderStrokeWidth: 1.5,
                                      borderColor: const Color(0xFFE61717).withValues(alpha: 0.7),
                                      useRadiusInMeter: true,
                                      radius: 800, // 800 meters radius
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _AnalysisCard(
              title: loc.incidentsPerCategory,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _BarRow(
                          label: isAr ? 'حريق' : 'Fire',
                          value: _getPercentage('fire'),
                          color: const Color(0xFFE61717),
                        ),
                        _BarRow(
                          label: isAr ? 'حادث سيارة' : 'Car Accident',
                          value: _getPercentage('accident'),
                          color: Colors.blue,
                        ),
                        _BarRow(
                          label: isAr ? 'طوارئ طبية' : 'Medical',
                          value: _getPercentage('medical'),
                          color: Colors.green,
                        ),
                        _BarRow(
                          label: isAr ? 'أخرى' : 'Other',
                          value: _getPercentage('other'),
                          color: Colors.grey,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFire(String type) {
    final t = type.toLowerCase();
    return t == 'fire' || t == 'hadi2';
  }

  bool _isAccident(String type) {
    final t = type.toLowerCase();
    return t == 'accident' || t == 'car accident';
  }

  bool _isMedical(String type) {
    final t = type.toLowerCase();
    return t == 'medical' || t == 'fainting' || t == 'heart attack';
  }

  double _getPercentage(String category) {
    if (_alerts.isEmpty) return 0.0;
    final total = _alerts.length;
    int count = 0;
    if (category == 'other') {
      count = _alerts
          .where((a) =>
              !_isFire(a.type) &&
              !_isAccident(a.type) &&
              !_isMedical(a.type))
          .length;
    } else if (category == 'fire') {
      count = _alerts.where((a) => _isFire(a.type)).length;
    } else if (category == 'accident') {
      count = _alerts.where((a) => _isAccident(a.type)).length;
    } else if (category == 'medical') {
      count = _alerts.where((a) => _isMedical(a.type)).length;
    }
    return count / total;
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'NotoSansArabic',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _AnalysisCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _BarRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
