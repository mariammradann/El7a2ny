import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/health_metric_model.dart';
import '../services/api_service.dart';
import '../services/health_connect_service.dart';
import '../core/localization/app_strings.dart';

/// Premium Health Dashboard Page with 5 sections:
/// A. Live Metrics Cards (heart rate, SpO2, steps, calories, sleep)
/// B. Personalized Baseline Section
/// C. Health Risk Score Widget (animated gauge)
/// D. Trends Section (simplified charts)
/// E. Alerts & Reports Section
class HealthDashboardPage extends StatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  State<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends State<HealthDashboardPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  HealthDashboardModel? _dashboard;
  bool _isLoading = true;
  String? _error;
  Timer? _autoRefresh;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadDashboard();
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadDashboard(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchHealthDashboard();
      if (data != null && mounted) {
        setState(() {
          _dashboard = HealthDashboardModel.fromJson(data);
          _isLoading = false;
          _error = null;
        });
      } else if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load health data';
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isLoading = true);
    await HealthConnectService().syncAllData();
    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isAr = context.loc.isAr;

    if (_isLoading && _dashboard == null) {
      return _buildLoadingSkeleton();
    }

    if (_error != null && _dashboard == null) {
      return _buildErrorState(isAr);
    }

    return RefreshIndicator(
      onRefresh: _triggerSync,
      color: const Color(0xFFE11D48),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Header with sync status
          _buildSyncHeader(isAr),
          const SizedBox(height: 8),

          // A. Health Risk Score (hero widget)
          _buildRiskScoreWidget(isAr),
          const SizedBox(height: 20),

          // B. Live Metrics
          _buildSectionTitle(isAr ? 'المؤشرات الحيوية' : 'Vital Signs', Icons.favorite_rounded),
          const SizedBox(height: 12),
          _buildLiveMetricsGrid(isAr),
          const SizedBox(height: 24),

          // C. Baseline Profile
          _buildSectionTitle(isAr ? 'الملف الشخصي الصحي' : 'Health Profile', Icons.person_pin_rounded),
          const SizedBox(height: 12),
          _buildBaselineSection(isAr),
          const SizedBox(height: 24),

          // D. Risk Score History (trend)
          _buildSectionTitle(isAr ? 'اتجاه المخاطر' : 'Risk Trend', Icons.trending_up_rounded),
          const SizedBox(height: 12),
          _buildRiskTrendChart(isAr),
          const SizedBox(height: 24),

          // E. Alerts & Anomalies
          _buildSectionTitle(isAr ? 'التنبيهات والحالات' : 'Alerts & Reports', Icons.notification_important_rounded),
          const SizedBox(height: 12),
          _buildAlertsSection(isAr),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SYNC HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSyncHeader(bool isAr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFFE11D48), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'مراقبة الصحة الذكية' : 'Smart Health Monitoring',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'NotoSansArabic'),
                ),
                Text(
                  isAr ? 'آخر تحديث: الآن' : 'Last update: Just now',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'NotoSansArabic'),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _triggerSync,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFF43F5E)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(isAr ? 'مزامنة' : 'Sync', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // A. RISK SCORE WIDGET (Hero)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRiskScoreWidget(bool isAr) {
    final score = _dashboard?.currentRiskScore?.score ?? 0;
    final level = _dashboard?.currentRiskScore?.riskLevel ?? 'normal';
    final explanation = _dashboard?.currentRiskScore?.explanation ?? (isAr ? 'كل المؤشرات ضمن المعدل الطبيعي' : 'All patterns appear within your normal range.');

    final Color scoreColor = _riskColor(level);
    final bool isHigh = score > 75;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A),
            scoreColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gauge
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = isHigh ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _RiskGaugePainter(score: score, color: scoreColor),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                          Text(
                            isAr ? 'درجة الخطورة' : 'Risk Score',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Risk level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Text(
              _riskLabel(level, isAr),
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Explanation
          Text(
            explanation,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontFamily: 'NotoSansArabic',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // B. LIVE METRICS GRID
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLiveMetricsGrid(bool isAr) {
    final d = _dashboard;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _metricCard(
                icon: Icons.favorite_rounded,
                gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
                label: isAr ? 'نبض القلب' : 'Heart Rate',
                value: d?.latestHeartRate?.toStringAsFixed(0) ?? '--',
                unit: 'bpm',
                isPulsing: true,
              )),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(
                icon: Icons.water_drop_rounded,
                gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                label: isAr ? 'أكسجين الدم' : 'SpO₂',
                value: d?.latestSpO2?.toStringAsFixed(0) ?? '--',
                unit: '%',
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricCard(
                icon: Icons.directions_walk_rounded,
                gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                label: isAr ? 'الخطوات' : 'Steps',
                value: d?.latestSteps != null
                    ? (d!.latestSteps! >= 1000
                        ? '${(d.latestSteps! / 1000).toStringAsFixed(1)}k'
                        : d.latestSteps!.toStringAsFixed(0))
                    : '--',
                unit: isAr ? 'خطوة' : 'steps',
              )),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(
                icon: Icons.local_fire_department_rounded,
                gradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
                label: isAr ? 'السعرات' : 'Calories',
                value: d?.latestCalories?.toStringAsFixed(0) ?? '--',
                unit: 'kcal',
              )),
            ],
          ),
          const SizedBox(height: 12),
          _metricCardWide(
            icon: Icons.bedtime_rounded,
            gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            label: isAr ? 'النوم' : 'Sleep',
            value: d?.latestSleepDuration != null
                ? '${(d!.latestSleepDuration! / 60).toStringAsFixed(1)}'
                : '--',
            unit: isAr ? 'ساعة' : 'hrs',
            subtitle: isAr ? 'الليلة الماضية' : 'Last night',
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required List<Color> gradient,
    required String label,
    required String value,
    required String unit,
    bool isPulsing = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gradient[0].withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.1),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              if (isPulsing)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: gradient[0],
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.6), blurRadius: 6)],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'NotoSansArabic')),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontFamily: 'NotoSansArabic')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontFamily: 'NotoSansArabic')),
        ],
      ),
    );
  }

  Widget _metricCardWide({
    required IconData icon,
    required List<Color> gradient,
    required String label,
    required String value,
    required String unit,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gradient[0].withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontFamily: 'NotoSansArabic')),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontFamily: 'NotoSansArabic')),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'NotoSansArabic')),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontFamily: 'NotoSansArabic')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // C. BASELINE SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBaselineSection(bool isAr) {
    final maturity = _dashboard?.profileMaturity;
    final baselines = _dashboard?.baselines ?? [];
    final isMature = maturity?.isMature ?? false;
    final progressPct = maturity?.progressPct ?? 0;
    final days = maturity?.daysCollected ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Maturity progress
            Row(
              children: [
                Icon(
                  isMature ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                  color: isMature ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isMature
                      ? (isAr ? 'الملف الشخصي مكتمل ✓' : 'Profile Complete ✓')
                      : (isAr ? 'جاري بناء الملف الشخصي...' : 'Building your profile...'),
                  style: TextStyle(
                    color: isMature ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPct / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFF334155),
                valueColor: AlwaysStoppedAnimation(
                  isMature ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? '$days / 14 يوم من البيانات' : '$days / 14 days of data',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'NotoSansArabic'),
            ),
            if (baselines.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 12),
              // Show key baselines
              ...baselines.take(4).map((b) => _buildBaselineRow(b, isAr)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBaselineRow(HealthBaselineModel baseline, bool isAr) {
    final icon = _metricIcon(baseline.metricType);
    final label = _metricLabel(baseline.metricType, isAr);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.6), size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontFamily: 'NotoSansArabic')),
          const Spacer(),
          Text(
            '${baseline.meanValue.toStringAsFixed(1)} ± ${baseline.stdValue.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'NotoSansArabic'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // D. RISK TREND (simplified bar chart)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRiskTrendChart(bool isAr) {
    final history = _dashboard?.riskScoreHistory.reversed.take(12).toList() ?? [];

    if (history.isEmpty) {
      return _buildEmptyCard(isAr ? 'لا توجد بيانات كافية بعد' : 'Not enough data yet');
    }

    final maxScore = history.map((s) => s.score).reduce(max).toDouble();
    final chartMax = max(maxScore, 20.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: history.map((score) {
                final h = (score.score / chartMax * 100).clamp(4.0, 100.0);
                final color = _riskColor(score.riskLevel);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${score.score}',
                          style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.8), color],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isAr ? 'الأقدم' : 'Oldest', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
              Text(isAr ? 'الأحدث' : 'Latest', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // E. ALERTS SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAlertsSection(bool isAr) {
    final anomalies = _dashboard?.recentAnomalies ?? [];
    final reports = _dashboard?.recentEmergencyReports ?? [];

    if (anomalies.isEmpty && reports.isEmpty) {
      return _buildEmptyCard(isAr ? 'لا توجد تنبيهات — كل شيء طبيعي ✅' : 'No alerts — Everything looks normal ✅');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...anomalies.take(5).map((a) => _buildAnomalyCard(a, isAr)),
          if (reports.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...reports.take(3).map((r) => _buildEmergencyReportCard(r, isAr)),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(HealthAnomalyModel anomaly, bool isAr) {
    final color = anomaly.isActive ? const Color(0xFFE11D48) : const Color(0xFF6B7280);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(anomaly.isActive ? 0.4 : 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  anomaly.isActive ? Icons.warning_amber_rounded : Icons.check_circle_outlined,
                  color: color, size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'نمط صحي غير عادي' : 'Unusual health pattern',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'NotoSansArabic'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _anomalyStatusLabel(anomaly.status, isAr),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            anomaly.explanation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontFamily: 'NotoSansArabic', height: 1.4),
          ),
          if (anomaly.isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    isAr ? 'أنا بخير' : "I'm OK",
                    const Color(0xFF10B981),
                    () => _respondToAnomaly(anomaly.anomalyId, 'ok'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionBtn(
                    isAr ? 'محتاج مساعدة' : 'Need Help',
                    const Color(0xFFE11D48),
                    () => _respondToAnomaly(anomaly.anomalyId, 'help'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _timeAgo(anomaly.createdAt, isAr),
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontFamily: 'NotoSansArabic'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyReportCard(HealthEmergencyReportModel report, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emergency_rounded, color: Color(0xFFE11D48), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'تقرير طوارئ صحي' : 'Health Emergency Report',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'NotoSansArabic'),
                ),
                Text(
                  '${isAr ? 'درجة الخطورة:' : 'Risk score:'} ${report.riskScore}',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'NotoSansArabic'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              report.status,
              style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'NotoSansArabic')),
        ),
      ),
    );
  }

  Future<void> _respondToAnomaly(String anomalyId, String response) async {
    await ApiService.respondToHealthAnomaly(anomalyId, response);
    await _loadDashboard();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE11D48), size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'NotoSansArabic')),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
      ),
      child: Center(
        child: Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontFamily: 'NotoSansArabic')),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFFE11D48),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text('Loading health data...', style: TextStyle(color: Colors.white54, fontFamily: 'NotoSansArabic')),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          Text(isAr ? 'تعذر تحميل بيانات الصحة' : 'Failed to load health data', style: const TextStyle(color: Colors.white54, fontFamily: 'NotoSansArabic')),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'normal': return const Color(0xFF10B981);
      case 'low': return const Color(0xFFFBBF24);
      case 'medium': return const Color(0xFFF97316);
      case 'high': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  String _riskLabel(String level, bool isAr) {
    if (isAr) {
      switch (level) {
        case 'normal': return 'طبيعي';
        case 'low': return 'منخفض';
        case 'medium': return 'متوسط';
        case 'high': return 'مرتفع';
        default: return 'غير معروف';
      }
    }
    switch (level) {
      case 'normal': return 'Normal';
      case 'low': return 'Low Risk';
      case 'medium': return 'Medium Risk';
      case 'high': return 'High Risk';
      default: return 'Unknown';
    }
  }

  String _anomalyStatusLabel(String status, bool isAr) {
    if (isAr) {
      switch (status) {
        case 'active': return 'نشط';
        case 'acknowledged': return 'تم الإقرار';
        case 'resolved': return 'تم الحل';
        case 'false_alarm': return 'إنذار كاذب';
        default: return status;
      }
    }
    switch (status) {
      case 'active': return 'Active';
      case 'acknowledged': return 'Acknowledged';
      case 'resolved': return 'Resolved';
      case 'false_alarm': return 'False Alarm';
      default: return status;
    }
  }

  IconData _metricIcon(String type) {
    switch (type) {
      case 'heart_rate': return Icons.favorite_rounded;
      case 'spo2': return Icons.water_drop_rounded;
      case 'steps': return Icons.directions_walk_rounded;
      case 'calories': return Icons.local_fire_department_rounded;
      case 'sleep_duration': return Icons.bedtime_rounded;
      case 'exercise': return Icons.fitness_center_rounded;
      default: return Icons.monitor_heart_rounded;
    }
  }

  String _metricLabel(String type, bool isAr) {
    if (isAr) {
      switch (type) {
        case 'heart_rate': return 'نبض القلب';
        case 'spo2': return 'أكسجين الدم';
        case 'steps': return 'الخطوات';
        case 'calories': return 'السعرات';
        case 'sleep_duration': return 'النوم';
        case 'exercise': return 'التمرين';
        default: return type;
      }
    }
    switch (type) {
      case 'heart_rate': return 'Heart Rate';
      case 'spo2': return 'SpO₂';
      case 'steps': return 'Steps';
      case 'calories': return 'Calories';
      case 'sleep_duration': return 'Sleep';
      case 'exercise': return 'Exercise';
      default: return type;
    }
  }

  String _timeAgo(DateTime dt, bool isAr) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    return isAr ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER: Risk Score Gauge
// ═══════════════════════════════════════════════════════════════════════════════

class _RiskGaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _RiskGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _degToRad(135),
      _degToRad(270),
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..shader = SweepGradient(
        startAngle: _degToRad(135),
        endAngle: _degToRad(405),
        colors: [color.withOpacity(0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 270;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _degToRad(135),
      _degToRad(sweepAngle),
      false,
      valuePaint,
    );

    // Glow effect at tip
    if (score > 0) {
      final tipAngle = _degToRad(135 + sweepAngle);
      final tipX = center.dx + radius * cos(tipAngle);
      final tipY = center.dy + radius * sin(tipAngle);

      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(tipX, tipY), 6, glowPaint);
    }
  }

  double _degToRad(double deg) => deg * pi / 180;

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
