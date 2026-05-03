import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/localization/app_strings.dart';
import '../models/activity_history_model.dart';
import '../services/api_service.dart';

class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key});

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  List<ActivityHistoryModel> _myHistory = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final history = await ApiService.fetchActivityHistory(
        isArabic: context.loc.isAr,
      );
      if (mounted) {
        setState(() {
          _myHistory = history;
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
        final item = _myHistory[index];
        return _HistoryCard(
          item: item,
          onTap: () {
            // Optional: Show details or perform action based on type
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ActivityHistoryModel item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    IconData icon;
    Color color;
    String typeLabel;

    switch (item.type) {
      case 'emergency':
        icon = Icons.emergency_rounded;
        color = Colors.redAccent;
        typeLabel = isAr ? 'طوارئ' : 'Emergency';
        break;
      case 'volunteer':
        icon = Icons.volunteer_activism_rounded;
        color = Colors.green;
        typeLabel = isAr ? 'مبادرة' : 'Initiative';
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = theme.primaryColor;
        typeLabel = isAr ? 'أخرى' : 'Other';
    }

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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy/MM/dd - hh:mm a').format(item.date),
                    style: TextStyle(
                      fontSize: 11,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
