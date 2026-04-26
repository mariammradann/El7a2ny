import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

class IncidentAnalysisPage extends StatelessWidget {
  const IncidentAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final isAr = loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.analysisTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic')),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _StatTile(label: loc.totalIncidents, value: '1,248', color: Colors.blue),
                const SizedBox(width: 12),
                _StatTile(label: loc.activeAlerts, value: '14', color: Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            _AnalysisCard(
              title: loc.heatMapTitle,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_rounded, size: 48, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(isAr ? 'خريطة حرارية تفاعلية' : 'Interactive Heatmap', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _AnalysisCard(
              title: loc.incidentsPerCategory,
              child: Column(
                children: [
                  _BarRow(label: isAr ? 'حريق' : 'Fire', value: 0.8, color: Colors.red),
                  _BarRow(label: isAr ? 'حادث سيارة' : 'Car Accident', value: 0.6, color: Colors.blue),
                  _BarRow(label: isAr ? 'طوارئ طبية' : 'Medical', value: 0.4, color: Colors.green),
                  _BarRow(label: isAr ? 'أخرى' : 'Other', value: 0.2, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'NotoSansArabic')),
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
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
