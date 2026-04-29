import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/localization/app_strings.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import 'alert_details_page.dart';

class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key});

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  List<AlertModel> _myHistory = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final allAlerts = await ApiService.fetchAlerts();
      if (mounted) {
        setState(() {
          _myHistory = allAlerts.where((a) => a.isMyAlert).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          loc.isAr ? 'سجل النشاطات' : 'Activity History',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'NotoSansArabic',
            color: theme.primaryColor,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: theme.primaryColor,
        child: _buildBody(theme, loc),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppStrings loc) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
            const SizedBox(height: 12),
            Text(loc.connError, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton(onPressed: _loadHistory, child: Text(loc.retry)),
          ],
        ),
      );
    }

    if (_myHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              loc.isAr ? 'لا يوجد سجل نشاطات حالياً' : 'No activity history yet',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _myHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final alert = _myHistory[index];
        return _HistoryCard(
          alert: alert,
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AlertDetailsPage(alert: alert, isMyAlerts: true),
              ),
            );
            if (result == true) {
              _loadHistory();
            }
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const _HistoryCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;
    final bool isResolved = alert.status == 'resolved';
    final bool isCancelled = alert.status == 'cancelled';
    final bool isActive = !isResolved && !isCancelled;

    Color statusColor;
    if (isActive) statusColor = Colors.orange;
    else if (isResolved) statusColor = Colors.green;
    else statusColor = Colors.grey;

    String statusText;
    if (isActive) statusText = isAr ? 'نشط' : 'Active';
    else if (isResolved) statusText = isAr ? 'تم الحل' : 'Resolved';
    else statusText = isAr ? 'ملغي' : 'Cancelled';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.crisis_alert_rounded, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.getLocalizedType(loc),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy/MM/dd - hh:mm a').format((alert.createdAt ?? DateTime.now()).toLocal()),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
