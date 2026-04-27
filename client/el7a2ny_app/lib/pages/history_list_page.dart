import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../models/activity_history_model.dart';
import 'package:intl/intl.dart';


class HistoryListPage extends StatelessWidget {
  final List<ActivityHistoryModel> history;

  const HistoryListPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,

      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'سجل النشاطات' : 'Activity History'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final h = history[index];
            IconData icon;
            Color color;
            switch (h.type) {
              case 'emergency':
                icon = Icons.emergency_rounded;
                color = Colors.redAccent;
                break;
              case 'volunteer':
                icon = Icons.volunteer_activism_rounded;
                color = Colors.green;
                break;
              default:
                icon = Icons.info_outline_rounded;
                color = theme.primaryColor;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                title: Text(
                  h.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      h.description,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(isAr ? 'yyyy/MM/dd - hh:mm a' : 'dd MMM yyyy, hh:mm a').format(h.date),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
