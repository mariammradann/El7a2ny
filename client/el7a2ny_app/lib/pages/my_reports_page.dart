import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../models/alert_model.dart';
import 'package:intl/intl.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  late Future<List<AlertModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = ApiService.fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isAr ? 'تقاريري' : 'My Reports',
          style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'NotoSansArabic'),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: FutureBuilder<List<AlertModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(isAr ? 'خطأ في تحميل التقارير' : 'Error loading reports'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _reportsFuture = ApiService.fetchAlerts()),
                    child: Text(isAr ? 'إعادة محاولة' : 'Retry'),
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data ?? [];
          
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_present_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'لا توجد تقارير حتى الآن' : 'No reports yet',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _reportsFuture = ApiService.fetchAlerts());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportCard(report: report, isAr: isAr, theme: theme);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AlertModel report;
  final bool isAr;
  final ThemeData theme;

  const _ReportCard({
    required this.report,
    required this.isAr,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(report.status),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.category.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(isAr ? 'dd/MM/yyyy - hh:mm a' : 'dd MMM yyyy, hh:mm a').format(report.createdAt ?? DateTime.now()),
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusLabel(report.status, isAr),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.description != null && report.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الوصف' : 'Description',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Media/Images Display
                if (report.mediaUrls != null && report.mediaUrls!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الصور والفيديوهات' : 'Photos & Videos',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: report.mediaUrls!.length,
                          itemBuilder: (context, idx) {
                            final mediaUrl = report.mediaUrls![idx];
                            return _MediaThumbnail(
                              mediaUrl: mediaUrl,
                              onTap: () => _showMediaFullscreen(context, mediaUrl),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Location Info
                if (report.latitude != null && report.longitude != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الموقع' : 'Location',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${isAr ? 'خط العرض' : 'Latitude'}: ${report.latitude?.toStringAsFixed(4)}\n${isAr ? 'خط الطول' : 'Longitude'}: ${report.longitude?.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return Icons.info_outline_rounded;
      case 'in_progress':
        return Icons.hourglass_top_rounded;
      case 'resolved':
        return Icons.check_circle_outline_rounded;
      case 'closed':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusLabel(String status, bool isAr) {
    switch (status.toLowerCase()) {
      case 'reported':
        return isAr ? 'تم الإبلاغ' : 'Reported';
      case 'in_progress':
        return isAr ? 'قيد التنفيذ' : 'In Progress';
      case 'resolved':
        return isAr ? 'تم حلها' : 'Resolved';
      case 'closed':
        return isAr ? 'مغلقة' : 'Closed';
      default:
        return status;
    }
  }

  void _showMediaFullscreen(BuildContext context, String mediaUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(
            mediaUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(isAr ? 'خطأ في تحميل الصورة' : 'Failed to load image'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final String mediaUrl;
  final VoidCallback onTap;

  const _MediaThumbnail({
    required this.mediaUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                    ),
                  );
                },
              ),
              // Click indicator
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
