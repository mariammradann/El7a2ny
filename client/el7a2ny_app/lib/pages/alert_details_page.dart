import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/localization/app_strings.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';

class AlertDetailsPage extends StatefulWidget {
  final AlertModel alert;
  final bool isMyAlerts;
  const AlertDetailsPage({
    super.key,
    required this.alert,
    this.isMyAlerts = false,
  });

  @override
  State<AlertDetailsPage> createState() => _AlertDetailsPageState();
}

class _AlertDetailsPageState extends State<AlertDetailsPage> {
  late int _totalVols;
  late int _currVols;
  late int _progress;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _totalVols = widget.alert.totalVolunteers;
    _currVols = widget.alert.currentVolunteers;
    _progress = (_totalVols > 0) ? (_currVols / _totalVols * 100).round() : 0;
  }

  bool _updatingStatus = false;

  Future<void> _updateAlertStatus(String newStatus) async {
    setState(() => _updatingStatus = true);
    try {
      await ApiService.updateAlertStatus(widget.alert.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.loc.isAr ? 'تم تحديث حالة البلاغ بنجاح' : 'Alert status updated successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.loc.isAr ? 'حدث خطأ أثناء التحديث' : 'Error updating status'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _joinVolunteers() async {
    if (_joined) return;
    try {
      await ApiService.respondToAlert(int.parse(widget.alert.id));
      if (!mounted) return;
      setState(() {
        _joined = true;
        _currVols++;
        _progress = min(100, (_currVols / _totalVols * 100).round());
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.loc.isAr ? 'تم تسجيل تطوعك! المساعدة في الطريق.' : 'Successfully registered! Help is on the way.'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.loc.isAr ? 'عذراً، حدث خطأ أثناء التسجيل.' : 'Error registering for alert.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.loc.isAr;
    Color bannerColor;
    IconData largeIcon;
    final typeLower = widget.alert.type.toLowerCase();

    if (typeLower.contains('fire') || typeLower.contains('حريق')) {
      bannerColor = const Color(0xFFEF4444);
      largeIcon = Icons.fire_extinguisher_rounded;
    } else if (typeLower.contains('medical') || typeLower.contains('طب')) {
      bannerColor = const Color(0xFFD97706);
      largeIcon = Icons.medical_services_rounded;
    } else if (typeLower.contains('security') || typeLower.contains('أمن')) {
      bannerColor = const Color(0xFFB45309);
      largeIcon = Icons.shield_rounded;
    } else {
      bannerColor = const Color(0xFF6366F1);
      largeIcon = Icons.emergency_rounded;
    }

    final dateStr = widget.alert.createdAt != null 
        ? DateFormat('dd/MM/yyyy').format(widget.alert.createdAt!) 
        : DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Area
                  SizedBox(
                    height: 250,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [bannerColor.withValues(alpha: 0.9), bannerColor],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          right: isAr ? -30 : null,
                          left: isAr ? null : -30,
                          bottom: -30,
                          child: Icon(largeIcon, size: 200, color: Colors.black.withValues(alpha: 0.08)),
                        ),
                        Positioned(
                          top: 40,
                          right: isAr ? 16 : null,
                          left: isAr ? null : 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                              child: Icon(isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                        // Active Pill
                        Positioned(
                          top: 45,
                          left: isAr ? 16 : null,
                          right: isAr ? null : 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Text(
                                  widget.isMyAlerts ? context.loc.completed : context.loc.activeStatusNow,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: onSurface),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: widget.isMyAlerts ? const Color(0xFF22C55E) : const Color(0xFF34D399),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Percentage Box
                        Positioned(
                          top: 100,
                          left: isAr ? 16 : null,
                          right: isAr ? null : 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.isMyAlerts ? const Color(0xFFF97316) : const Color(0xFFFF0000),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text('$_progress%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                                Text(context.loc.volunteeringRate, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: bannerColor, borderRadius: BorderRadius.circular(16)),
                              child: Text(widget.alert.getLocalizedType(context.loc), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(widget.alert.getLocalizedSeverity(context.loc), style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.alert.getLocalizedType(context.loc) + (widget.isMyAlerts ? context.loc.pastAlert : context.loc.activeStatus),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: onSurface),
                        ),
                        const SizedBox(height: 20),
                        
                        // Updated Row with Address logic
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? theme.colorScheme.surface : theme.primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3B82F6)),
                                        SizedBox(width: 6),
                                        Text('LOCATION', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (widget.alert.address != null && widget.alert.address!.isNotEmpty)
                                          ? widget.alert.address!
                                          : widget.alert.getLocalizedLocation(context.loc),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? theme.colorScheme.surface : theme.colorScheme.secondary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFA855F7)),
                                        SizedBox(width: 6),
                                        Text('TIME', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.alert.timeAgoLocalized(context.loc).isEmpty ? context.loc.justNow : widget.alert.timeAgoLocalized(context.loc),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Volunteers Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? theme.colorScheme.surface : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? theme.dividerColor.withValues(alpha: 0.1) : const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                                        child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(context.loc.volunteers, style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('$_currVols', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: onSurface)),
                                  const SizedBox(width: 6),
                                  Text('${context.loc.outOfLabel} $_totalVols', style: TextStyle(fontSize: 16, color: onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 8,
                                decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: _progress,
                                      child: Container(decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4))),
                                    ),
                                    Expanded(flex: 100 - _progress, child: const SizedBox()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Details
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 18),
                                  const SizedBox(width: 8),
                                  Text(context.loc.alertDetails, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (widget.alert.description != null)
                                Text(widget.alert.description!, style: TextStyle(color: onSurface.withValues(alpha: 0.7), height: 1.7, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Action Button
            if (!(widget.isMyAlerts || widget.alert.isMyAlert))
              Positioned(
                bottom: 24, left: 20, right: 20,
                child: Container(
                  decoration: BoxDecoration(boxShadow: [BoxShadow(color: _joined ? Colors.grey.withValues(alpha: 0.4) : const Color(0xFF10B981).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: ElevatedButton(
                    onPressed: _joined ? null : _joinVolunteers,
                    style: ElevatedButton.styleFrom(backgroundColor: _joined ? Colors.grey.shade400 : const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_joined ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(_joined ? context.loc.joinedBtn : (isAr ? ' انا جي ' : 'I am coming'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              )
            else if (widget.alert.status.toLowerCase() != 'resolved' && widget.alert.status.toLowerCase() != 'cancelled')
              Positioned(
                bottom: 24, left: 20, right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updatingStatus ? null : () => _updateAlertStatus('cancelled'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text(isAr ? 'إلغاء البلاغ' : 'Cancel Report', style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _updatingStatus ? null : () => _updateAlertStatus('resolved'),
                        style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _updatingStatus 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(isAr ? 'انتهى الخطر' : 'Danger Ended', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}