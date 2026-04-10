import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/alert_model.dart';
import '../services/api_service.dart';
import 'alert_details_page.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AlertModel> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: const BackButton(color: Color(0xFF0F172A)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFE11D48),
                unselectedLabelColor: const Color(0xFF475569),
                indicatorColor: const Color(0xFFE11D48),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic'),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'NotoSansArabic'),
                tabs: const [
                  Tab(text: 'البلاغات النشطة'),
                  Tab(text: 'بلاغاتي'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildList(isMyAlerts: false),
            _buildList(isMyAlerts: true),
          ],
        ),
      ),
    );
  }

  Widget _buildList({required bool isMyAlerts}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text('مش قادر يوصل للسيرفر', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('حاول تاني'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    final displayAlerts = isMyAlerts 
        ? _alerts.where((a) => a.id % 2 == 0).toList() // Mocking "My Alerts"
        : _alerts;

    if (displayAlerts.isEmpty) {
      return const Center(
        child: Text('مفيش بلاغات متسجلة', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFE11D48),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: displayAlerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, i) => _AlertCard(alert: displayAlerts[i], isMyAlerts: isMyAlerts),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool isMyAlerts;

  const _AlertCard({required this.alert, required this.isMyAlerts});

  @override
  Widget build(BuildContext context) {
    // Determine colors and faux imagery based on type
    Color bannerColor;
    IconData largeIcon;
    double iconAngle = 0;
    
    if (alert.type.contains('حريق') || alert.type.contains('نار')) {
      bannerColor = const Color(0xFFEF4444);
      largeIcon = Icons.fire_extinguisher_rounded;
    } else if (alert.type.contains('طب') || alert.type.contains('اسعاف')) {
      bannerColor = const Color(0xFFD97706);
      largeIcon = Icons.medical_services_rounded;
    } else if (alert.type.contains('مرور') || alert.type.contains('سير') || alert.type.contains('حادث')) {
      bannerColor = const Color(0xFFB45309);
      largeIcon = Icons.car_crash_rounded;
    } else if (alert.type.contains('فيضان') || alert.type.contains('كوارث')) {
      bannerColor = const Color(0xFFEA580C);
      largeIcon = Icons.flood_rounded;
    } else {
      bannerColor = const Color(0xFF6366F1);
      largeIcon = Icons.emergency_rounded;
    }

    // Mock progress and volunteers
    final rand = Random(alert.id);
    final progress = isMyAlerts ? rand.nextInt(20) + 80 : rand.nextInt(50) + 10;
    final totalVols = rand.nextInt(50) + 50;
    final currVols = (progress / 100 * totalVols).round();

    // Mocks for description
    final mockDesc = isMyAlerts 
        ? 'تم التعامل مع البلاغ وإخماده بنجاح بمساعدة $currVols متطوع واستقرار الأوضاع.'
        : '${alert.type} في المنطقة، نحتاج لسرعة توفير متطوعين للالتحام مع فرق الطوارئ وتقديم الدعم لحين وصول بقية القوات.';
    
    final dateStr = alert.createdAt != null 
        ? DateFormat('dd/MM/yyyy').format(alert.createdAt!)
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    final timeColor = const Color(0xFFE11D48);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AlertDetailsPage(alert: alert, isMyAlerts: isMyAlerts),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image Area
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bannerColor, bannerColor.withOpacity(0.8)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Faint Background Icon
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Transform.rotate(
                    angle: iconAngle,
                    child: Icon(largeIcon, size: 160, color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                
                // Completed Pill (if my alerts && completed)
                if (isMyAlerts)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('مكتمل', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Orange/Red Percentage Bubble
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMyAlerts ? const Color(0xFFF97316) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text('$progress%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),

                // Type White Pill
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: Text(alert.type, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time & Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        alert.type + (isMyAlerts ? ' - بلاغ سابق' : ' نشط'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      alert.timeAgo.isEmpty ? 'حالا' : alert.timeAgo,
                      style: TextStyle(color: timeColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Location Line
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(alert.location, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 16, color: Color(0xFFE11D48)),
                  ],
                ),
                const SizedBox(height: 4),

                // Date Line
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  mockDesc,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),

                // Bottom Volunteers Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_left_rounded, color: Color(0xFF94A3B8)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('المتطوعون', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text('$currVols من $totalVols', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFFE11D48)),
                      ),
                    ],
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
