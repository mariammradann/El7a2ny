import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  List<AlertModel> _alerts = [];
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
      final alerts = await ApiService.fetchAlerts();
      if (mounted) setState(() { _alerts = alerts; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFFAF5FF)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الحوادث النشطة',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text('اسحب للأسفل للتحديث',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            _ErrorView(onRetry: _load)
          else if (_alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Text('✅', style: TextStyle(fontSize: 48)),
                SizedBox(height: 8),
                Text('مفيش حوادث نشطة دلوقتي',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
              ]),
            )
          else
            Column(
              children: _alerts
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AlertCard(alert: a),
                      ))
                  .toList(),
            ),
        ]),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final List<Color> iconGradient;
    final Color statusColor;
    final String severityLabel;
    final IconData icon;

    switch (alert.severity) {
      case 'high':
        borderColor = const Color(0xFFFCA5A5);
        bgColor = const Color(0xFFFFF1F2);
        iconGradient = [const Color(0xFFEF4444), const Color(0xFFF97316)];
        statusColor = const Color(0xFF3B82F6);
        severityLabel = 'حرج';
        icon = Icons.local_fire_department_rounded;
        break;
      case 'medium':
        borderColor = const Color(0xFFFDBA74);
        bgColor = const Color(0xFFFFF7ED);
        iconGradient = [const Color(0xFFF97316), const Color(0xFFF59E0B)];
        statusColor = const Color(0xFFF59E0B);
        severityLabel = 'عاجل';
        icon = Icons.local_hospital_rounded;
        break;
      default:
        borderColor = const Color(0xFF6EE7B7);
        bgColor = const Color(0xFFF0FDF4);
        iconGradient = [const Color(0xFF10B981), const Color(0xFF14B8A6)];
        statusColor = const Color(0xFF10B981);
        severityLabel = 'عادي';
        icon = Icons.shield_rounded;
    }

    final Color statusBg = alert.status == 'جاري التعامل'
        ? const Color(0xFF3B82F6)
        : alert.status == 'في الطريق'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: iconGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: iconGradient[0].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(children: [
              Text(alert.type,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(severityLabel, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(alert.status == 'تم الحل' ? Icons.check_circle : Icons.show_chart_rounded,
                  color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text(alert.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF64748B)),
          const SizedBox(width: 4),
          Expanded(child: Text(alert.location,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(alert.timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(width: 16),
          const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text('${alert.units} وحدات بتتعامل',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ]),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
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
