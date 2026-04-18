import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import 'dashboard_tab.dart';
import 'emergency_tab.dart';
import 'safety_tab.dart';
import 'alerts_tab.dart';
import 'sensors_page.dart';
import 'emergency_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  List<Map<String, dynamic>> _getTabs(BuildContext context) => [
    {
      'label': context.loc.dashboard,
      'activeGradient': const [Color(0xFF3B82F6), Color(0xFF6366F1)],
    },
    {
      'label': context.loc.emergencyCall,
      'activeGradient': const [Color(0xFFEF4444), Color(0xFFF97316)],
    },
    {
      'label': context.loc.safetyInfo,
      'activeGradient': const [Color(0xFF10B981), Color(0xFF14B8A6)],
    },
    {
      'label': context.loc.activeAlertsTab,
      'activeGradient': const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    },
    {
      'label': context.loc.sensorsTab,
      'activeGradient': const [Color(0xFF16A34A), Color(0xFF15803D)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _activeTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs(context);
    return Directionality(
      textDirection: context.loc.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const EmergencyChatScreen()),
            );
          },
          backgroundColor: const Color(0xFF2D3243),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
        ),
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _buildHeader(context),

            // ── Tab Bar ─────────────────────────────────────────────
            _buildTabBar(context, tabs),

            // ── Tab Content ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  DashboardTab(),
                  EmergencyTab(),
                  SafetyTab(),
                  AlertsTab(),
                  SensorsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3730A3)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        right: 20,
        left: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right side: logo + title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.emergencySystemTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.loc.emergencyServices24_7,
                    style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          // Left side: status badge
          _PulseBadge(),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, List<Map<String, dynamic>> tabs) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: List<Color>.from(
                  tabs[_activeTab]['activeGradient'] as List),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: tabs
              .map((t) => Tab(text: t['label'] as String))
              .toList(),
        ),
      ),
    );
  }
}

// ── Pulsing badge widget ─────────────────────────────────────────────────────
class _PulseBadge extends StatefulWidget {
  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _opacity = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34D399),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.loc.allSystemsOperationalStatus,
            style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
